import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RefreshSessionUseCase {
  RefreshSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> execute() {
    return _repository.refreshSession();
  }
}

