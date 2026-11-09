enum UserRole {
  superadmin,
  admin,
  pdo;

  static UserRole fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      case 'pdo':
      default:
        return UserRole.pdo;
    }
  }

  String toDbValue() => name;
}

enum AccountStatus {
  active,
  pending,
  blocked;

  static AccountStatus fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'active':
        return AccountStatus.active;
      case 'blocked':
        return AccountStatus.blocked;
      case 'pending':
      default:
        return AccountStatus.pending;
    }
  }

  String toDbValue() => name;
}

class AuthorizedDispatcher {
  const AuthorizedDispatcher({
    required this.id,
    required this.uuid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String uuid;
  final String email;
  final String name;
  final UserRole role;
  final AccountStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAuthorized => status == AccountStatus.active;
  bool get isBlocked => status == AccountStatus.blocked;
  bool get isPending => status == AccountStatus.pending;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superadmin;

  factory AuthorizedDispatcher.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is num
        ? rawId.toInt()
        : (int.tryParse(rawId?.toString() ?? '') ?? 0);
    return AuthorizedDispatcher(
      id: parsedId,
      uuid: (json['uuid'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'pdo'),
      status: AccountStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'email': email,
    'name': name,
    'role': role.toDbValue(),
    'status': status.toDbValue(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}
