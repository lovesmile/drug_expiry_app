import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ItemStatus { valid, warning, expired }

enum UsageStatus { active, usedUp, discarded }

enum ItemCategory { drug, food, cosmetic, dailyNecessity, other }

class Item {
  final int? id;
  final String name;
  final String? subtitle;
  final String? specification;
  final String? batchNumber;
  final String? manufacturer;
  final DateTime expiryDate;
  final String? photoPath;
  final int iconCodePoint;
  final UsageStatus usageStatus;
  final ItemCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    this.id,
    required this.name,
    this.subtitle,
    this.specification,
    this.batchNumber,
    this.manufacturer,
    required this.expiryDate,
    this.photoPath,
    int? iconCodePoint,
    this.usageStatus = UsageStatus.active,
    this.category = ItemCategory.drug,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : iconCodePoint = (iconCodePoint != null && iconCodePoint != 0) ? iconCodePoint : Icons.inventory_2.codePoint,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  ItemStatus get status {
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return ItemStatus.expired;
    if (diff <= 30) return ItemStatus.warning;
    return ItemStatus.valid;
  }

  String get formattedExpiryDate {
    return DateFormat('yyyy-MM-dd').format(expiryDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'generic_name': subtitle,
      'specification': specification,
      'batch_number': batchNumber,
      'manufacturer': manufacturer,
      'expiry_date': DateFormat('yyyy-MM-dd').format(expiryDate),
      'photo_path': photoPath,
      'icon_code_point': iconCodePoint,
      'usage_status': usageStatus.name,
      'category': category.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      subtitle: map['generic_name'] as String?,
      specification: map['specification'] as String?,
      batchNumber: map['batch_number'] as String?,
      manufacturer: map['manufacturer'] as String?,
      expiryDate: DateFormat('yyyy-MM-dd').parse(map['expiry_date'] as String),
      photoPath: map['photo_path'] as String?,
      iconCodePoint: map['icon_code_point'] as int?,
      usageStatus: (map['usage_status'] as String?) == null
          ? UsageStatus.active
          : UsageStatus.values.firstWhere(
              (e) => e.name == map['usage_status'],
              orElse: () => UsageStatus.active,
            ),
      category: (map['category'] as String?) == null
          ? ItemCategory.drug
          : ItemCategory.values.firstWhere(
              (e) => e.name == map['category'],
              orElse: () => ItemCategory.drug,
            ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Item copyWith({
    int? id,
    String? name,
    String? subtitle,
    String? specification,
    String? batchNumber,
    String? manufacturer,
    DateTime? expiryDate,
    String? photoPath,
    int? iconCodePoint,
    UsageStatus? usageStatus,
    ItemCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      specification: specification ?? this.specification,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      expiryDate: expiryDate ?? this.expiryDate,
      photoPath: photoPath ?? this.photoPath,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      usageStatus: usageStatus ?? this.usageStatus,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
