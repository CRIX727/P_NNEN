import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/remote/device_api.dart';

class PushNotificationService {
  PushNotificationService(this._api);

  final DeviceApi _api;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _api.register(token, 'android');
      }
      await _tokenSubscription?.cancel();
      _tokenSubscription = messaging.onTokenRefresh.listen((value) {
        _api.register(value, 'android');
      });
    } catch (_) {
      // Firebase is optional until google-services.json is configured.
    }
  }

  Future<void> dispose() async => _tokenSubscription?.cancel();
}
