class User {
  final int? id;
  final String nickname;
  final String? phone;
  final String? avatarPath;
  final String role; // 'admin' or 'member'

  User({
    this.id,
    required this.nickname,
    this.phone,
    this.avatarPath,
    this.role = 'admin',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'phone': phone,
      'avatar_path': avatarPath,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      phone: map['phone'] as String?,
      avatarPath: map['avatar_path'] as String?,
      role: map['role'] as String? ?? 'admin',
    );
  }

  User copyWith({
    int? id,
    String? nickname,
    String? phone,
    String? avatarPath,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      role: role ?? this.role,
    );
  }
}