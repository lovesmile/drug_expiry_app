class User {
  final int? id;
  final String nickname;
  final String? phone;
  final String? avatarPath;
  final String role; // 'admin' or 'member'
  final bool isPremium;
  final int recordLimit;
  final int recordCount;

  User({
    this.id,
    required this.nickname,
    this.phone,
    this.avatarPath,
    this.role = 'admin',
    this.isPremium = false,
    this.recordLimit = 10,
    this.recordCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'phone': phone,
      'avatar_path': avatarPath,
      'role': role,
      'is_premium': isPremium ? 1 : 0,
      'record_limit': recordLimit,
      'record_count': recordCount,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      phone: map['phone'] as String?,
      avatarPath: map['avatar_path'] as String?,
      role: map['role'] as String? ?? 'admin',
      isPremium: map['is_premium'] == 1,
      recordLimit: map['record_limit'] as int? ?? 10,
      recordCount: map['record_count'] as int? ?? 0,
    );
  }

  User copyWith({
    int? id,
    String? nickname,
    String? phone,
    String? avatarPath,
    String? role,
    bool? isPremium,
    int? recordLimit,
    int? recordCount,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      role: role ?? this.role,
      isPremium: isPremium ?? this.isPremium,
      recordLimit: recordLimit ?? this.recordLimit,
      recordCount: recordCount ?? this.recordCount,
    );
  }
}
