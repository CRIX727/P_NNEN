import 'package:flutter/foundation.dart';

import '../../core/errors/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/usecases/load_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_session_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required LoadSessionUseCase loadSessionUseCase,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required RefreshSessionUseCase refreshSessionUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loadSessionUseCase = loadSessionUseCase,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _refreshSessionUseCase = refreshSessionUseCase,
        _logoutUseCase = logoutUseCase;

  final LoadSessionUseCase _loadSessionUseCase;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final RefreshSessionUseCase _refreshSessionUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthState _state = const AuthState.initial();
  AuthState get state => _state;

  Future<void> bootstrap() async {
    _emit(_state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      final savedSession = await _loadSessionUseCase.execute();
      if (savedSession == null) {
        _emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }

      final session = await _restoreSession(savedSession);
      _emit(AuthState(status: AuthStatus.authenticated, session: session));
    } catch (error) {
      await _logoutUseCase.execute();
      _emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          message: 'No fue posible recuperar la sesión',
        ),
      );
    }
  }

  Future<void> login({
    required String correo,
    required String password,
  }) async {
    _emit(_state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      final session = await _loginUseCase.execute(
        correo: correo,
        password: password,
      );
      _emit(AuthState(status: AuthStatus.authenticated, session: session));
    } catch (error) {
      _emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: _normalizeMessage(error),
        ),
      );
    }
  }

  Future<void> register({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
  }) async {
    _emit(_state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      final session = await _registerUseCase.execute(
        nombre: nombre,
        correo: correo,
        password: password,
        rol: rol,
      );
      _emit(AuthState(status: AuthStatus.authenticated, session: session));
    } catch (error) {
      _emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: _normalizeMessage(error),
        ),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final session = await _refreshSessionUseCase.execute();
      _emit(AuthState(status: AuthStatus.authenticated, session: session));
    } catch (error) {
      _emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: _normalizeMessage(error),
        ),
      );
    }
  }

  Future<void> logout() async {
    _emit(_state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      await _logoutUseCase.execute();
    } finally {
      _emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<AuthSession> _restoreSession(AuthSession savedSession) async {
    try {
      return await _refreshSessionUseCase.execute();
    } catch (error) {
      if (error is AuthRepositoryException && error.retryable) {
        return savedSession;
      }
      rethrow;
    }
  }

  void _emit(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  String _normalizeMessage(Object error) {
    final message = error.toString();
    if (message.contains('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }
    return message;
  }
}
