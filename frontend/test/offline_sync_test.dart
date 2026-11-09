import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nnen_app/data/local/local_database.dart';
import 'package:nnen_app/data/sync/network_monitor.dart';
import 'package:nnen_app/data/sync/sync_manager.dart';

class _SuccessfulAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late LocalDatabase database;

  setUp(() {
    database = LocalDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('guarda y recupera datos locales aunque no exista servidor', () async {
    await database.cacheRecord(
      type: 'patient',
      remoteId: 7,
      ownerKey: 'nutri@test',
      value: {'id': 7, 'nombre': 'Paciente offline'},
    );

    final records = await database.readRecords(
      type: 'patient',
      ownerKey: 'nutri@test',
      remoteId: 7,
    );

    expect(records, hasLength(1));
    expect(records.single['nombre'], 'Paciente offline');
  });

  test('encola cambios y los elimina después de sincronizar', () async {
    await database.enqueue(
      method: 'PUT',
      endpoint: '/nutricionista/pacientes/7',
      payload: {'nombre': 'Actualizado offline'},
    );
    expect(await database.pendingCount(), 1);

    final adapter = _SuccessfulAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final network = NetworkMonitor();
    final manager = SyncManager(dio, database, network);

    expect(await manager.synchronize(), 1);
    expect(adapter.requests, 1);
    expect(await database.pendingCount(), 0);

    manager.dispose();
    await network.dispose();
  });

  test('conserva la operación pendiente cuando el servidor falla', () async {
    await database.enqueue(
      method: 'POST',
      endpoint: '/nutricionista/pacientes',
      payload: {'nombre': 'Pendiente'},
    );
    final dio = Dio()..httpClientAdapter = _FailingAdapter();
    final network = NetworkMonitor();
    final manager = SyncManager(dio, database, network);

    expect(await manager.synchronize(), 0);
    expect(await database.pendingCount(), 1);

    manager.dispose();
    await network.dispose();
  });

  test('no sobrescribe un cambio local pendiente con una descarga remota',
      () async {
    await database.cacheRecord(
      type: 'patient',
      remoteId: 7,
      ownerKey: 'nutri@test',
      value: {'id': 7, 'nombre': 'Cambio local'},
      isSynced: false,
    );
    await database.cacheRecord(
      type: 'patient',
      remoteId: 7,
      ownerKey: 'nutri@test',
      value: {'id': 7, 'nombre': 'Dato remoto antiguo'},
    );

    final records = await database.readRecords(
      type: 'patient',
      ownerKey: 'nutri@test',
      remoteId: 7,
    );
    expect(records.single['nombre'], 'Cambio local');
  });
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}
