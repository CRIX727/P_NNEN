import '../entities/auth_session.dart';
import '../entities/user_role.dart';

abstract class AuthRepository {
  Future<AuthSession?> getSavedSession();

  Future<AuthSession> login({
    required String correo,
    required String password,
  });

  Future<AuthSession> register({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
  });

  Future<AuthSession> refreshSession();

  Future<void> logout();
}

