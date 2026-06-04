import 'package:isar/isar.dart';
import 'package:smart_planner/features/sync/domain/sync_entity_type.dart';
import 'package:smart_planner/features/sync/domain/sync_pending_op.dart';

part 'sync_record.g.dart';

/// Maps a local entity to a remote id, etag, and pending outbox op.
@collection
class SyncRecord {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  late SyncEntityType entityType;

  @Index()
  late int localId;

  @Index()
  String? remoteId;

  String? etag;

  DateTime? lastSyncedAt;

  @Enumerated(EnumType.ordinal)
  SyncPendingOp pendingOp = SyncPendingOp.none;
}
