import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../constants.dart';
import '../models/item.dart';
import '../models/family_member.dart';
import '../models/reminder_settings.dart';
import '../models/user.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppStrings.dbName);
    return openDatabase(
      path,
      version: 4,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppStrings.drugsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        generic_name TEXT,
        specification TEXT,
        batch_number TEXT,
        manufacturer TEXT,
        expiry_date TEXT NOT NULL,
        photo_path TEXT,
        icon_code_point INTEGER NOT NULL DEFAULT 0,
        usage_status TEXT NOT NULL DEFAULT 'active',
        category TEXT NOT NULL DEFAULT 'drug',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppStrings.familyTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'member',
        avatar_path TEXT,
        invite_code TEXT,
        joined_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppStrings.remindersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reminder_30_days INTEGER NOT NULL DEFAULT 1,
        time_30_days TEXT NOT NULL DEFAULT '20:00',
        reminder_7_days INTEGER NOT NULL DEFAULT 1,
        time_7_days TEXT NOT NULL DEFAULT '09:00',
        reminder_3_days INTEGER NOT NULL DEFAULT 1,
        time_3_days TEXT NOT NULL DEFAULT '09:00',
        reminder_expired INTEGER NOT NULL DEFAULT 1,
        time_expired TEXT NOT NULL DEFAULT '09:00'
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppStrings.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT NOT NULL,
        phone TEXT,
        avatar_path TEXT,
        role TEXT NOT NULL DEFAULT 'admin',
        is_premium INTEGER NOT NULL DEFAULT 0,
        record_limit INTEGER NOT NULL DEFAULT 10,
        record_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppStrings.barcodeCacheTable} (
        barcode TEXT PRIMARY KEY,
        name TEXT,
        generic_name TEXT,
        manufacturer TEXT,
        specification TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${AppStrings.drugsTable} ADD COLUMN icon_code_point INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE ${AppStrings.drugsTable} ADD COLUMN usage_status TEXT NOT NULL DEFAULT \'active\'');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE ${AppStrings.drugsTable} ADD COLUMN category TEXT NOT NULL DEFAULT \'drug\'');
    }
  }

  // Item CRUD

  Future<int> insertItem(Item item) async {
    final db = await DatabaseService.database;
    return db.insert(AppStrings.drugsTable, item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await DatabaseService.database;
    final maps = await db.query(AppStrings.drugsTable, orderBy: 'expiry_date ASC');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      AppStrings.drugsTable,
      where: 'name LIKE ? OR generic_name LIKE ? OR manufacturer LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<List<Item>> getItemsByStatus(ItemStatus status) async {
    final all = await getAllItems();
    return all.where((d) => d.status == status).toList();
  }

  Future<Item?> getItem(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(AppStrings.drugsTable, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<int> updateItem(Item item) async {
    final db = await DatabaseService.database;
    return db.update(
      AppStrings.drugsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await DatabaseService.database;
    return db.delete(AppStrings.drugsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Family Member CRUD

  Future<int> insertFamilyMember(FamilyMember member) async {
    final db = await DatabaseService.database;
    return db.insert(AppStrings.familyTable, member.toMap());
  }

  Future<List<FamilyMember>> getAllFamilyMembers() async {
    final db = await DatabaseService.database;
    final maps = await db.query(AppStrings.familyTable, orderBy: 'joined_at DESC');
    return maps.map((m) => FamilyMember.fromMap(m)).toList();
  }

  Future<int> updateFamilyMember(FamilyMember member) async {
    final db = await DatabaseService.database;
    return db.update(
      AppStrings.familyTable,
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await DatabaseService.database;
    return db.delete(AppStrings.familyTable, where: 'id = ?', whereArgs: [id]);
  }

  // Reminder Settings

  Future<ReminderSettings?> getReminderSettings() async {
    final db = await DatabaseService.database;
    final maps = await db.query(AppStrings.remindersTable, limit: 1);
    if (maps.isEmpty) return null;
    return ReminderSettings.fromMap(maps.first);
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    final db = await DatabaseService.database;
    final existing = await getReminderSettings();
    if (existing != null) {
      await db.update(
        AppStrings.remindersTable,
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      await db.insert(AppStrings.remindersTable, settings.toMap());
    }
  }

  // Barcode Cache

  Future<void> cacheBarcode(String barcode, Map<String, String?> data) async {
    final db = await DatabaseService.database;
    await db.insert(
      AppStrings.barcodeCacheTable,
      {
        'barcode': barcode,
        'name': data['name'],
        'generic_name': data['generic_name'],
        'manufacturer': data['manufacturer'],
        'specification': data['specification'],
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String?>?> getCachedBarcode(String barcode) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      AppStrings.barcodeCacheTable,
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isEmpty) return null;
    final row = maps.first;
    return {
      'name': row['name'] as String?,
      'generic_name': row['generic_name'] as String?,
      'manufacturer': row['manufacturer'] as String?,
      'specification': row['specification'] as String?,
    };
  }

  Future<int> getBarcodeCacheCount() async {
    final db = await DatabaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppStrings.barcodeCacheTable}');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> clearBarcodeCache() async {
    final db = await DatabaseService.database;
    await db.delete(AppStrings.barcodeCacheTable);
  }

  // User CRUD

  Future<int> insertUser(User user) async {
    final db = await DatabaseService.database;
    return db.insert(AppStrings.usersTable, user.toMap());
  }

  Future<User?> getUser(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(AppStrings.usersTable, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getCurrentUser() async {
    final db = await DatabaseService.database;
    final maps = await db.query(AppStrings.usersTable, limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await DatabaseService.database;
    return db.update(
      AppStrings.usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await DatabaseService.database;
    return db.delete(AppStrings.usersTable, where: 'id = ?', whereArgs: [id]);
  }

  // Full backup/restore

  Future<String> exportAllData() async {
    final db = await DatabaseService.database;
    final drugs = await db.query(AppStrings.drugsTable);
    final members = await db.query(AppStrings.familyTable);
    final settings = await db.query(AppStrings.remindersTable);
    final users = await db.query(AppStrings.usersTable);

    final export = {
      'version': 4,
      'exported_at': DateTime.now().toIso8601String(),
      'drugs': drugs,
      'family_members': members,
      'reminder_settings': settings,
      'users': users,
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/expiry_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(export));
    return file.path;
  }

  Future<Map<String, int>> importAllData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('文件不存在');

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    final db = await DatabaseService.database;

    int drugsImported = 0;
    int membersImported = 0;

    await db.transaction((txn) async {
      if (data['drugs'] is List) {
        for (final d in (data['drugs'] as List).cast<Map<String, dynamic>>()) {
          // Remove id so it gets auto-incremented
          final copy = Map<String, dynamic>.from(d)..remove('id');
          try {
            await txn.insert(AppStrings.drugsTable, copy);
            drugsImported++;
          } catch (_) {}
        }
      }

      if (data['family_members'] is List) {
        for (final m in (data['family_members'] as List).cast<Map<String, dynamic>>()) {
          final copy = Map<String, dynamic>.from(m)..remove('id');
          try {
            await txn.insert(AppStrings.familyTable, copy);
            membersImported++;
          } catch (_) {}
        }
      }

      if (data['reminder_settings'] is List && (data['reminder_settings'] as List).isNotEmpty) {
        final s = (data['reminder_settings'] as List).first as Map<String, dynamic>;
        final copy = Map<String, dynamic>.from(s)..remove('id');
        final existing = await txn.query(AppStrings.remindersTable);
        if (existing.isNotEmpty) {
          await txn.update(AppStrings.remindersTable, copy, where: 'id = ?', whereArgs: [existing.first['id']]);
        } else {
          await txn.insert(AppStrings.remindersTable, copy);
        }
      }
    });

    return {'drugs': drugsImported, 'members': membersImported};
  }
}
