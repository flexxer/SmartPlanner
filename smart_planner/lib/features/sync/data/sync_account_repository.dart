import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/sync/domain/entities/sync_account.dart';

/// CRUD for connected [SyncAccount] rows.
class SyncAccountRepository {
  SyncAccountRepository({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<SyncAccount>> getEnabled() =>
      _db.syncAccounts.filter().isEnabledEqualTo(true).findAll();

  Future<SyncAccount?> findByEmail({
    required String provider,
    required String accountEmail,
  }) =>
      _db.syncAccounts
          .filter()
          .providerEqualTo(provider)
          .accountEmailEqualTo(accountEmail)
          .findFirst();

  Future<SyncAccount?> getById(Id id) => _db.syncAccounts.get(id);

  Future<Id> upsert(SyncAccount account) =>
      _db.writeTxn(() => _db.syncAccounts.put(account));
}
