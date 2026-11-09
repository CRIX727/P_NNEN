import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/services/session_manager.dart';

class ApiClient {
  ApiClient._();

  static Dio create(SessionManager sessionManager) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    Future<void>? refreshInFlight;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await sessionManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final alreadyRetried = request.extra['authRetry'] == true;
          if (error.response?.statusCode != 401 || alreadyRetried) {
            handler.next(error);
            return;
          }

          final refreshToken = await sessionManager.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            handler.next(error);
            return;
          }

          try {
            refreshInFlight ??= _refreshTokens(sessionManager, refreshToken)
                .whenComplete(() => refreshInFlight = null);
            await refreshInFlight;
            final accessToken = await sessionManager.getAccessToken();
            if (accessToken == null || accessToken.isEmpty) {
              handler.next(error);
              return;
            }
            request.headers['Authorization'] = 'Bearer $accessToken';
            request.extra['authRetry'] = true;
            final retryResponse = await dio.fetch<dynamic>(request);
            handler.resolve(retryResponse);
          } on DioException {
            handler.next(error);
          }
        },
      ),
    );

    return dio;
  }

  static Future<void> _refreshTokens(
    SessionManager sessionManager,
    String refreshToken,
  ) async {
    // This client intentionally has no auth interceptor to avoid recursion.
    final refreshClient = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ));
    final response = await refreshClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data ?? <String, dynamic>{};
    final accessToken = data['accessToken'] as String?;
    final newRefreshToken = data['refreshToken'] as String?;
    if (accessToken == null || newRefreshToken == null) {
      throw DioException(requestOptions: response.requestOptions);
    }
    await sessionManager.updateTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
    );
  }
}
