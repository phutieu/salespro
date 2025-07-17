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
}
