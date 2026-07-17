enum UserRole {
  driver,
  parent,
  admin;

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.parent,
      );
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
    this.mustChangePassword = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? photoUrl;

  /// Set for accounts an admin provisioned with the school's default password.
  /// They must choose their own before they can use the app — see
  /// `ChangePasswordPage`. The server clears it once they do.
  final bool mustChangePassword;

  bool get isDriver => role == UserRole.driver;
  bool get isParent => role == UserRole.parent;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.fromString(json['role'] as String?),
        phone: json['phone'] as String?,
        photoUrl: json['photoUrl'] as String?,
        // Absent on a cached user written before this field existed, so it
        // defaults to false rather than locking someone out of a session they
        // already have.
        mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'phone': phone,
        'photoUrl': photoUrl,
        'mustChangePassword': mustChangePassword,
      };

  User copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    bool? mustChangePassword,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email,
        role: role,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
