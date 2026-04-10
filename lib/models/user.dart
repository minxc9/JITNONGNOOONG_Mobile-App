class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final bool? isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      isActive: json['isActive'] ?? json['enabled'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phoneNumber': phoneNumber,
        'isActive': isActive,
      };
}
