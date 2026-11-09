import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../local/local_database.dart';
import 'network_monitor.dart';

class SyncManager {
  SyncManager(this._dio, this._database, this._network);

  final Dio _dio;
  final LocalDatabase _database;
  final NetworkMonitor _network;
  bool _running = false;
  Timer? _timer;
  StreamSubscription<bool>? _networkSubscription;
  final Map<String, Future<void> Function()> _downloaders = {};
  final _statusController = StreamController<SyncStatus>.broadcast();

  SyncStatus _status = SyncStatus.idle;

  SyncStatus get status => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void registerDownloader(String ownerKey, Future<void> Function() callback) {
    _downloaders[ownerKey] = callback;
  }

  void unregisterDownloader(String ownerKey) {
    _downloaders.remove(ownerKey);
  }

  void start() {
    _network.start();
    _networkSubscription ??= _network.status.listen((online) {
      if (online) synchronize();
    });
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      synchronize();
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _networkSubscription?.cancel();
    _networkSubscription = null;
    _downloaders.clear();
    _statusController.close();
  }

  Future<int> synchronize() async {
    if (_running) return 0;
    if (!await _network.check()) {
      _setStatus(SyncStatus.offline);
      return 0;
    }
    _running = true;
    _setStatus(SyncStatus.syncing);
    var synchronized = 0;
    try {
      final entries = await _database.pendingQueue();
      for (final entry in entries) {
        final nextAttempt = entry.nextAttemptAt == null
            ? null
            : DateTime.tryParse(entry.nextAttemptAt!);
        if (nextAttempt != null &&
            nextAttempt.isAfter(DateTime.now().toUtc())) {
          continue;
        }
        if (entry.attempts >= entry.maxAttempts) {
          continue;
        }
        try {
          await _dio.request<dynamic>(
            entry.endpoint,
            data: jsonDecode(entry.payload),
            options: Options(method: entry.method),
          );
          await _database.removeQueueEntry(entry.id);
          await _database.markRecordSynced(
            type: entry.recordType,
            ownerKey: entry.ownerKey,
            remoteId: entry.remoteId,
          );
          synchronized++;
          _network.reportSuccess();
        } catch (error) {
          await _database.markQueueError(entry.id, error.toString());
          if (error is DioException && error.response?.statusCode == 409) {
            await _database.markRecordConflict(
              type: entry.recordType,
              ownerKey: entry.ownerKey,
              remoteId: entry.remoteId,
            );
          }
          _network.reportFailure();
          break;
        }
      }
      for (final downloader in _downloaders.values) {
        try {
          await downloader();
        } catch (_) {
          // A failed pull must not discard locally queued writes.
        }
      }
      _setStatus(SyncStatus.idle);
    } finally {
      _running = false;
    }
    return synchronized;
  }

  void _setStatus(SyncStatus value) {
    _status = value;
    if (!_statusController.isClosed) _statusController.add(value);
  }
}

enum SyncStatus { idle, syncing, offline }
