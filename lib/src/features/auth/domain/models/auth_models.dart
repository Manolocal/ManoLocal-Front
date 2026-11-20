import '../../../../core/enums/backend_enums.dart';

/// Usuario autenticado devuelto por `/auth/*` en ManoLocal-Back.
class AuthUserModel {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final UserStatus? status;
  final DateTime? createdAt;

  const AuthUserModel({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.status,
    this.createdAt,
  });

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : email;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      role: UserRole.fromString(json['role']?.toString()),
      status: json['status'] != null
          ? UserStatus.fromString(json['status']?.toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (name != null) 'name': name,
        'role': role.value,
        if (status != null) 'status': status!.value,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

/// DTO de registro equivalente a `RegisterDto` en NestJS.
class RegisterRequestModel {
  final String email;
  final String password;
  final UserRole role;
  final String? name;

  const RegisterRequestModel({
    required this.email,
    required this.password,
    required this.role,
    this.name,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
        'role': role.value,
        if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      };
}

/// Respuesta de `POST /auth/login` cuando se envía el código PIN 2FA al correo.
class LoginTwoFactorChallengeModel {
  final String message;
  final String email;

  const LoginTwoFactorChallengeModel({
    required this.message,
    required this.email,
  });

  factory LoginTwoFactorChallengeModel.fromJson(Map<String, dynamic> json) {
    return LoginTwoFactorChallengeModel(
      message: json['message']?.toString() ??
          'Código de verificación 2FA enviado al correo electrónico',
      email: json['email']?.toString() ?? '',
    );
  }
}

/// Respuesta de `POST /auth/verify-2fa` con el token JWT y datos de usuario.
class AuthSessionModel {
  final String accessToken;
  final AuthUserModel user;

  const AuthSessionModel({
    required this.accessToken,
    required this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken']?.toString() ??
        json['access_token']?.toString() ??
        '';
    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic>
        ? AuthUserModel.fromJson(rawUser)
        : const AuthUserModel(id: '', email: '', role: UserRole.empleador);

    return AuthSessionModel(
      accessToken: token,
      user: user,
    );
  }
}

/// Respuesta de los endpoints de verificación por rol (`/auth/*-only`).
class RoleAccessResponseModel {
  final String message;
  final AuthUserModel user;

  const RoleAccessResponseModel({
    required this.message,
    required this.user,
  });

  factory RoleAccessResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return RoleAccessResponseModel(
      message: json['message']?.toString() ?? '',
      user: rawUser is Map<String, dynamic>
          ? AuthUserModel.fromJson(rawUser)
          : const AuthUserModel(id: '', email: '', role: UserRole.empleador),
    );
  }
}
