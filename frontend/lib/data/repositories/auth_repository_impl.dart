import 'package:dio/dio.dart';

import '../../core/errors/auth_exception.dart';
import '../../core/services/session_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dto/auth_dtos.dart';
import '../remote/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi authApi,
    required SessionManager sessionManager,
  })  : _authApi = authApi,
        _sessionManager = sessionManager;

  final AuthApi _authApi;
  final SessionManager _sessionManager;

  @override
  Future<AuthSession?> getSavedSession() async {
    return _sessionManager.readSession();
  }

  @override
  Future<AuthSession> login({
    required String correo,
    required String password,
  }) async {
    final response = await _handleAuth(
      () => _authApi.login(
        LoginRequestDto(correo: correo, password: password),
      ),
    );
    final session = _mapToSession(response);
    await _sessionManager.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String nombre,
    required String correo,
    required String password,
    required UserRole rol,
  }) async {
    final response = await _handleAuth(
      () => _authApi.register(
        RegisterRequestDto(
          nombre: nombre,
          correo: correo,
          password: password,
          rol: rol,
        ),
      ),
    );
    final session = _mapToSession(response);
    await _sessionManager.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> refreshSession() async {
    final refreshToken = await _sessionManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthRepositoryException('No existe sesión activa');
    }

    final response = await _handleAuth(
      () => _authApi.refresh(
        RefreshTokenRequestDto(refreshToken: refreshToken),
      ),
    );
    final session = _mapToSession(response);
    await _sessionManager.saveSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _sessionManager.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await runCatching(() => _authApi.logout(LogoutRequestDto(refreshToken: refreshToken)));
    }
    await _sessionManager.clear();
  }

  Future<AuthResponseDto> _handleAuth(
    Future<AuthResponseDto> Function() action,
  ) async {
    try {
      return await action();
    } on DioException catch (error) {
      final message = _extractMessage(error);
      throw AuthRepositoryException(
        message,
        retryable: _isRetryable(error),
      );
    } catch (error) {
      throw AuthRepositoryException(
        error is AuthRepositoryException
            ? error.message
            : 'No se pudo completar la autenticación',
      );
    }
  }

  AuthSession _mapToSession(AuthResponseDto response) {
    return AuthSession(
      userId: response.usuario.id,
      name: response.usuario.nombre,
      email: response.usuario.correo,
      role: response.usuario.rol,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
  }

  String _extractMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'El servidor tardó demasiado en responder';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor';
      default:
        return 'No se pudo completar la autenticación';
    }
  }

  bool _isRetryable(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => false,
    };
  }
}

Future<void> runCatching(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {}
}
