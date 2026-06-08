import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/sync/domain/entities/sync_record.dart';
import 'package:smart_planner/features/sync/domain/sync_entity_type.dart';
import 'package:smart_planner/features/sync/domain/sync_pending_op.dart';

/// CRUD for [SyncRecord] rows (local ↔ remote mapping).
class SyncRecordRepository {
  SyncRecordRepository({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<SyncRecord?> findForLocal({
    required SyncEntityType entityType,
    required int localId,
  }) =>
      _db.syncRecords
          .filter()
          .entityTypeEqualTo(entityType)
          .localIdEqualTo(localId)
          .findFirst();

  Future<SyncRecord?> findByRemoteId(String remoteId) =>
      _db.syncRecords.filter().remoteIdEqualTo(remoteId).findFirst();

  Future<Id> upsert(SyncRecord record) =>
      _db.writeTxn(() => _db.syncRecords.put(record));

  Future<void> markSynced({
    required SyncEntityType entityType,
    required int localId,
    required String remoteId,
    String? etag,
  }) async {
    await _db.writeTxn(() async {
      SyncRecord? row = await _db.syncRecords
          .filter()
          .entityTypeEqualTo(entityType)
          .localIdEqualTo(localId)
          .findFirst();
      row ??= SyncRecord()
        ..entityType = entityType
        ..localId = localId;
      row
        ..remoteId = remoteId
        ..etag = etag
        ..lastSyncedAt = DateTime.now()
        ..pendingOp = SyncPendingOp.none;
      await _db.syncRecords.put(row);
    });
  }

  Future<void> setPendingOp({
    required SyncEntityType entityType,
    required int localId,
    required SyncPendingOp pendingOp,
  }) async {
    await _db.writeTxn(() async {
      SyncRecord? row = await _db.syncRecords
          .filter()
          .entityTypeEqualTo(entityType)
          .localIdEqualTo(localId)
          .findFirst();
      row ??= SyncRecord()
        ..entityType = entityType
        ..localId = localId;
      row.pendingOp = pendingOp;
      await _db.syncRecords.put(row);
    });
  }

  Future<void> deleteForLocal({
    required SyncEntityType entityType,
    required int localId,
  }) async {
    await _db.writeTxn(() async {
      final SyncRecord? row = await _db.syncRecords
          .filter()
          .entityTypeEqualTo(entityType)
          .localIdEqualTo(localId)
          .findFirst();
      if (row != null) {
        await _db.syncRecords.delete(row.id);
      }
    });
  }
}
