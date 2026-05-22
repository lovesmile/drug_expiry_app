class FamilyMember {
  final int? id;
  final String name;
  final String role; // 'admin' or 'member'
  final String? avatarPath;
  final String? inviteCode;
  final DateTime joinedAt;

  FamilyMember({
    this.id,
    required this.name,
    this.role = 'member',
    this.avatarPath,
    this.inviteCode,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar_path': avatarPath,
      'invite_code': inviteCode,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as int?,
      name: map['name'] as String,
      role: map['role'] as String? ?? 'member',
      avatarPath: map['avatar_path'] as String?,
      inviteCode: map['invite_code'] as String?,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  FamilyMember copyWith({
    int? id,
    String? name,
    String? role,
    String? avatarPath,
    String? inviteCode,
    DateTime? joinedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      inviteCode: inviteCode ?? this.inviteCode,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
