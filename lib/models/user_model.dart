class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool emailVerified;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emailVerified,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      emailVerified: json['emailVerified'] as bool,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'emailVerified': emailVerified,
      'role': role,
    };
  }
}

