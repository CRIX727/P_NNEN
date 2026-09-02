import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const envBaseUrl = String.fromEnvironment('NNEN_API_BASE_URL', defaultValue: '');
    return envBaseUrl.isNotEmpty ? envBaseUrl : _defaultApiBaseUrl();
  }

  static String _defaultApiBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      default:
        return 'http://localhost:3000/api';
    }
  }
}
