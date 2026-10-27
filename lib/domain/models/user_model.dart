class UserModel {
  final String id;
  final String email;
  final String name;
  final String? role;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (role != null) 'role': role,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, name: $name, role: $role)';
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserModel? user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Adaptable a las respuestas comunes de NestJS (e.g. { access_token, user } o { token, ... })
    final token = json['access_token'] ?? json['accessToken'] ?? json['token'] ?? '';
    final refreshToken = json['refresh_token'] ?? json['refreshToken'];
    UserModel? user;

    if (json['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(json['user']);
    } else if (json['data'] is Map<String, dynamic> && json['data']['user'] != null) {
      user = UserModel.fromJson(json['data']['user']);
    }

    return AuthResponse(
      accessToken: token,
      refreshToken: refreshToken,
      user: user,
    );
  }
}
