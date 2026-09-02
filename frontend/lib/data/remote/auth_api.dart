import 'package:dio/dio.dart';

import '../dto/auth_dtos.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> login(LoginRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<AuthResponseDto> register(RegisterRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<AuthResponseDto> refresh(RefreshTokenRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> logout(LogoutRequestDto request) async {
    await _dio.post<void>(
      '/auth/logout',
      data: request.toJson(),
    );
  }
}

