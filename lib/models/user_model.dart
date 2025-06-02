class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String name;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.name,
    required this.token,
  });

  // Factory constructor to handle the conversion of JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '', // Use empty string if '_id' is null
      username: json['username'] ?? '', // Default to empty string if 'username' is null
      email: json['email'] ?? '', // Default to empty string if 'email' is null
      role: json['role'] ?? '', // Default to empty string if 'role' is null
      name: json['name'] ?? json['username'] ?? '', // Use username as name if name is null
      token: json['token'] ?? '', // Default to empty string if 'token' is null
    );
  }
}
