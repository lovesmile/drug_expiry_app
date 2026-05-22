import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/family_member.dart';
import '../services/database_service.dart';

class FamilyProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<FamilyMember> _members = [];
  bool _isLoading = false;

  List<FamilyMember> get members => _members;
  bool get isLoading => _isLoading;
  int get memberCount => _members.length;
  int get adminCount => _members.where((m) => m.role == 'admin').length;

  Future<void> loadMembers() async {
    _isLoading = true;
    notifyListeners();
    _members = await _db.getAllFamilyMembers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMember(FamilyMember member) async {
    final code = _generateInviteCode();
    final newMember = member.copyWith(inviteCode: code);
    await _db.insertFamilyMember(newMember);
    await loadMembers();
  }

  Future<void> updateMember(FamilyMember member) async {
    await _db.updateFamilyMember(member);
    await loadMembers();
  }

  Future<void> removeMember(int id) async {
    await _db.deleteFamilyMember(id);
    await loadMembers();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
