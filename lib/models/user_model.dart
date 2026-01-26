class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool emailVerified;
  final String role;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.emailVerified,
    required this.role,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      emailVerified: json['emailVerified'] as bool,
      role: json['role'] as String,
      profilePicture: json['profilePicture'] as String?,
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
      'profilePicture': profilePicture,
    };
  }
}

