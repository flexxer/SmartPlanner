import 'package:isar_community/isar.dart';

part 'sync_account.g.dart';

/// Connected cloud account (Google, etc.) for future sync.
@collection
class SyncAccount {
  Id id = Isar.autoIncrement;

  /// Provider key, e.g. `google`.
  @Index()
  late String provider;

  @Index()
  late String accountEmail;

  String? displayName;

  DateTime? lastSyncedAt;

  bool isEnabled = true;
}
