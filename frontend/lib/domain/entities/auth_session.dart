import 'user_role.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  final int userId;
  final String name;
  final String email;
  final UserRole role;
  final String accessToken;
  final String refreshToken;
}

