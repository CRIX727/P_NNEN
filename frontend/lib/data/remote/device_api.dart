import 'package:dio/dio.dart';

class DeviceApi {
  DeviceApi(this._dio);

  final Dio _dio;

  Future<void> register(String token, String platform) async {
    await _dio.post<void>('/auth/device', data: {
      'token': token,
      'plataforma': platform,
    });
  }

  Future<void> remove(String token) async {
    await _dio.post<void>('/auth/device/remove', data: {'token': token});
  }
}
