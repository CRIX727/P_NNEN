import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_role.dart';

class SessionManager {
  SessionManager({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'nnen_access_token';
  static const _refreshTokenKey = 'nnen_refresh_token';
  static const _userIdKey = 'nnen_user_id';
  static const _userNameKey = 'nnen_user_name';
  static const _userEmailKey = 'nnen_user_email';
  static const _userRoleKey = 'nnen_user_role';

  Future<void> saveSession(AuthSession session) async {
    await _secureStorage.write(key: _accessTokenKey, value: session.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _secureStorage.write(key: _userIdKey, value: session.userId.toString());
    await _secureStorage.write(key: _userNameKey, value: session.name);
    await _secureStorage.write(key: _userEmailKey, value: session.email);
    await _secureStorage.write(key: _userRoleKey, value: session.role.name);
  }

  Future<AuthSession?> readSession() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final userId = await _secureStorage.read(key: _userIdKey);
    final userName = await _secureStorage.read(key: _userNameKey);
    final userEmail = await _secureStorage.read(key: _userEmailKey);
    final userRole = await _secureStorage.read(key: _userRoleKey);

    if (accessToken == null ||
        refreshToken == null ||
        userId == null ||
        userName == null ||
        userEmail == null ||
        userRole == null) {
      return null;
    }

    final parsedRole = userRoleFromName(userRole);
    if (parsedRole == null) {
      return null;
    }

    return AuthSession(
      userId: int.tryParse(userId) ?? 0,
      name: userName,
      email: userEmail,
      role: parsedRole,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<String?> getAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _userRoleKey);
  }
}

UserRole? userRoleFromName(String value) {
  for (final role in UserRole.values) {
    if (role.name == value) {
      return role;
    }
  }
  return null;
}
