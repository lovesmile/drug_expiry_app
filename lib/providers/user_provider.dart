import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    _user = await _db.getCurrentUser();
    if (_user == null) {
      // Create default admin user on first launch
      final defaultUser = User(nickname: 'Admin', role: 'admin');
      final id = await _db.insertUser(defaultUser);
      _user = defaultUser.copyWith(id: id);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    await _db.updateUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> updateNickname(String nickname) async {
    if (_user == null) return;
    final updated = _user!.copyWith(nickname: nickname);
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> incrementRecordCount() async {
    if (_user == null) return;
    final updated = _user!.copyWith(recordCount: _user!.recordCount + 1);
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> decrementRecordCount() async {
    if (_user == null || _user!.recordCount <= 0) return;
    final updated = _user!.copyWith(recordCount: _user!.recordCount - 1);
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      isPremium: value,
      recordLimit: value ? 999999 : 10,
    );
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }
}
