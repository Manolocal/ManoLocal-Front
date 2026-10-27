import '../models/user_model.dart';

abstract class AuthRepository {
  /// Inicia sesión con credenciales contra el backend NestJS
  Future<UserModel> login({required String email, required String password});

  /// Cierra la sesión activa y limpia las credenciales locales
  Future<void> logout();

  /// Obtiene el usuario autenticado actualmente si existe sesión activa
  Future<UserModel?> getCurrentUser();

  /// Verifica si existe un token guardado
  Future<bool> isAuthenticated();
}
