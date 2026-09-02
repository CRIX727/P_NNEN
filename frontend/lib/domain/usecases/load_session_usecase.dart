import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoadSessionUseCase {
  LoadSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession?> execute() {
    return _repository.getSavedSession();
  }
}

