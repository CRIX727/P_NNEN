import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  NetworkMonitor();

  void start() {
    if (_subscription != null) return;
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _setOnline(result.any((item) => item != ConnectivityResult.none));
    });
    _refresh();
  }

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  bool get isOnline => _online;
  Stream<bool> get status => _controller.stream;

  Future<bool> check() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _setOnline(result.any((item) => item != ConnectivityResult.none));
    } catch (_) {
      // Unit tests and unsupported platforms may not expose the native channel.
      // The first API request still updates the state through reportSuccess/
      // reportFailure.
    }
    return _online;
  }

  void reportFailure() => _setOnline(false);
  void reportSuccess() => _setOnline(true);

  void _setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _controller.add(value);
  }

  Future<void> _refresh() async {
    try {
      await check();
    } catch (_) {
      // The first real API request remains the final connectivity check.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
