import '../entities/auth_session.dart';
import '../entities/user_role.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> execute({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
  }) {
    return _repository.register(
      nombre: nombre,
      correo: correo,
      password: password,
      rol: rol,
    );
  }
}

