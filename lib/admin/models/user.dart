enum UserRole { Admin, Sales, Accountant }

class User {
  final String id;
  String name;
  String phoneNumber;
  String email;
  UserRole role;
  bool isActive;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.' + (map['role'] ?? 'Admin'),
        orElse: () => UserRole.Admin,
      ),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.toString().split('.').last,
      'isActive': isActive,
    };
  }
}
