import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_database.g.dart';

class CachedRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recordType => text()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get ownerKey => text()();
  TextColumn get payload => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  TextColumn get conflictState => text().withDefault(const Constant('none'))();
  TextColumn get lastSyncedAt => text().nullable()();
}

class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get method => text()();
  TextColumn get endpoint => text()();
  TextColumn get payload => text()();
  TextColumn get createdAt => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get ownerKey => text().withDefault(const Constant(''))();
  TextColumn get recordType => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get maxAttempts => integer().withDefault(const Constant(8))();
  TextColumn get nextAttemptAt => text().nullable()();
}

@DriftDatabase(tables: [CachedRecords, SyncQueueEntries])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase({QueryExecutor? executor})
      : super(executor ?? driftDatabase(name: 'nnen_local'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(cachedRecords, cachedRecords.isSynced);
            await m.addColumn(cachedRecords, cachedRecords.conflictState);
            await m.addColumn(cachedRecords, cachedRecords.lastSyncedAt);
            await m.addColumn(syncQueueEntries, syncQueueEntries.ownerKey);
            await m.addColumn(syncQueueEntries, syncQueueEntries.recordType);
            await m.addColumn(syncQueueEntries, syncQueueEntries.remoteId);
            await m.addColumn(syncQueueEntries, syncQueueEntries.maxAttempts);
            await m.addColumn(syncQueueEntries, syncQueueEntries.nextAttemptAt);
          }
        },
      );

  Future<void> cacheRecord({
    required String type,
    required int? remoteId,
    required String ownerKey,
    required Map<String, dynamic> value,
    bool isSynced = true,
    bool deleted = false,
    String conflictState = 'none',
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await (select(cachedRecords)
          ..where((row) => row.recordType.equals(type))
          ..where((row) => row.ownerKey.equals(ownerKey))
          ..where((row) => remoteId == null
              ? row.remoteId.isNull()
              : row.remoteId.equals(remoteId)))
        .getSingleOrNull();
    // Never overwrite a local pending edit with a background download. The
    // pending write remains the winner until the server acknowledges it.
    if (existing != null && !existing.isSynced && isSynced) {
      await (update(cachedRecords)..where((row) => row.id.equals(existing.id)))
          .write(
              const CachedRecordsCompanion(conflictState: Value('local-wins')));
      return;
    }
    final companion = CachedRecordsCompanion(
      recordType: Value(type),
      remoteId: Value(remoteId),
      ownerKey: Value(ownerKey),
      payload: Value(jsonEncode(value)),
      updatedAt: Value(now),
      deleted: Value(deleted),
      isSynced: Value(isSynced && (remoteId == null || remoteId >= 0)),
      conflictState: Value(conflictState),
      lastSyncedAt: isSynced ? Value(now) : const Value.absent(),
    );
    if (existing == null) {
      await into(cachedRecords).insert(companion);
    } else {
      await (update(cachedRecords)..where((row) => row.id.equals(existing.id)))
          .write(companion);
    }
  }

  Future<List<Map<String, dynamic>>> readRecords({
    required String type,
    required String ownerKey,
    int? remoteId,
  }) async {
    final query = select(cachedRecords)
      ..where((row) => row.recordType.equals(type))
      ..where((row) => row.ownerKey.equals(ownerKey))
      ..where((row) => row.deleted.equals(false));
    if (remoteId != null) {
      query.where((row) => row.remoteId.equals(remoteId));
    }
    final rows = await query.get();
    return rows
        .map((row) => jsonDecode(row.payload))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> markRecordSynced({
    required String type,
    required String ownerKey,
    required int? remoteId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final query = update(cachedRecords)
      ..where((row) => row.recordType.equals(type))
      ..where((row) => row.ownerKey.equals(ownerKey));
    if (remoteId == null) {
      query.where((row) => row.remoteId.isNull());
    } else {
      query.where((row) => row.remoteId.equals(remoteId));
    }
    await query.write(CachedRecordsCompanion(
      isSynced: const Value(true),
      lastSyncedAt: Value(now),
      conflictState: const Value('none'),
    ));
  }

  Future<void> markRecordConflict({
    required String type,
    required String ownerKey,
    required int? remoteId,
    String state = 'conflict',
  }) async {
    final query = update(cachedRecords)
      ..where((row) => row.recordType.equals(type))
      ..where((row) => row.ownerKey.equals(ownerKey));
    if (remoteId == null) {
      query.where((row) => row.remoteId.isNull());
    } else {
      query.where((row) => row.remoteId.equals(remoteId));
    }
    await query.write(CachedRecordsCompanion(
      isSynced: const Value(false),
      conflictState: Value(state),
    ));
  }

  Future<void> softDeleteRecord({
    required String type,
    required String ownerKey,
    required int remoteId,
  }) async {
    await (update(cachedRecords)
          ..where((row) => row.recordType.equals(type))
          ..where((row) => row.ownerKey.equals(ownerKey))
          ..where((row) => row.remoteId.equals(remoteId)))
        .write(const CachedRecordsCompanion(
      deleted: Value(true),
      isSynced: Value(false),
    ));
  }

  Future<void> enqueue({
    required String method,
    required String endpoint,
    required Map<String, dynamic> payload,
    String ownerKey = '',
    String recordType = '',
    int? remoteId,
  }) async {
    // The newest local edit replaces older pending edits for the same target.
    await (delete(syncQueueEntries)
          ..where((row) => row.method.equals(method))
          ..where((row) => row.endpoint.equals(endpoint))
          ..where((row) => row.ownerKey.equals(ownerKey)))
        .go();
    await into(syncQueueEntries).insert(SyncQueueEntriesCompanion.insert(
      method: method,
      endpoint: endpoint,
      payload: jsonEncode(payload),
      createdAt: DateTime.now().toUtc().toIso8601String(),
      ownerKey: Value(ownerKey),
      recordType: Value(recordType),
      remoteId: Value(remoteId),
    ));
    final pendingQuery = update(cachedRecords)
      ..where((row) => row.ownerKey.equals(ownerKey))
      ..where((row) => row.recordType.equals(recordType));
    if (remoteId == null) {
      pendingQuery.where(
          (row) => row.remoteId.isNull() | row.remoteId.isSmallerThanValue(0));
    } else {
      pendingQuery.where((row) => row.remoteId.equals(remoteId));
    }
    await pendingQuery.write(const CachedRecordsCompanion(
      isSynced: Value(false),
    ));
  }

  Future<List<SyncQueueEntry>> pendingQueue() => (select(syncQueueEntries)
        ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
      .get();

  Future<void> removeQueueEntry(int id) async {
    await (delete(syncQueueEntries)..where((row) => row.id.equals(id))).go();
  }

  Future<void> markQueueError(int id, String error) async {
    final entry = await (select(syncQueueEntries)
          ..where((row) => row.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return;
    final nextAttempt = DateTime.now()
        .toUtc()
        .add(Duration(seconds: 1 << (entry.attempts.clamp(0, 5))))
        .toIso8601String();
    await (update(syncQueueEntries)..where((row) => row.id.equals(id))).write(
      SyncQueueEntriesCompanion(
        attempts: Value(entry.attempts + 1),
        lastError: Value(error),
        nextAttemptAt: Value(nextAttempt),
      ),
    );
  }

  Future<int> pendingCount() async =>
      (select(syncQueueEntries)).get().then((rows) => rows.length);

  Future<int> failedCount() async => (select(syncQueueEntries)
        ..where((row) => row.attempts.isBiggerThanValue(0)))
      .get()
      .then((rows) => rows.length);
}
