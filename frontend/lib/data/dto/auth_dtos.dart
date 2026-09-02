import '../../domain/entities/user_role.dart';
import '../../core/services/session_manager.dart';

class LoginRequestDto {
  const LoginRequestDto({
    required this.correo,
    required this.password,
  });

  final String correo;
  final String password;

  Map<String, dynamic> toJson() => {
        'correo': correo,
        'password': password,
      };
}

class RegisterRequestDto {
  const RegisterRequestDto({
    required this.nombre,
    required this.correo,
    required this.password,
    required this.rol,
  });

  final String nombre;
  final String correo;
  final String password;
  final UserRole rol;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': rol.name,
      };
}

class RefreshTokenRequestDto {
  const RefreshTokenRequestDto({
    required this.refreshToken,
  });

  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };
}

class LogoutRequestDto {
  const LogoutRequestDto({
    required this.refreshToken,
  });

  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };
}

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: userRoleFromName(json['rol'] as String? ?? '') ?? UserRole.paciente,
    );
  }

  final int id;
  final String nombre;
  final String correo;
  final UserRole rol;
}

class AuthResponseDto {
  const AuthResponseDto({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      success: json['success'] as bool? ?? false,
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      usuario: AuthUserDto.fromJson(
        Map<String, dynamic>.from(json['usuario'] as Map),
      ),
    );
  }

  final bool success;
  final String accessToken;
  final String refreshToken;
  final AuthUserDto usuario;
}
