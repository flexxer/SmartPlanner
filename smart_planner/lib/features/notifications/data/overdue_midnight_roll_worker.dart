import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/notifications/data/overdue_midnight_roll_service.dart';

/// Workmanager handler: midnight overdue roll (~00:05 local).
abstract final class OverdueMidnightRollWorker {
  OverdueMidnightRollWorker._();

  static Future<bool> run() async {
    try {
      await IsarDatabase.init();
      await OverdueMidnightRollService().runIfNeeded();
      return true;
    } catch (_) {
      return false;
    }
  }
}
