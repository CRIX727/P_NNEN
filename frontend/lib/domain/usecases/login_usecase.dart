import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> execute({
    required String correo,
    required String password,
  }) {
    return _repository.login(
      correo: correo,
      password: password,
    );
  }
}

