import 'package:flutter/foundation.dart';
import 'package:smart_planner/features/notifications/data/day_status_background_sync.dart';
import 'package:smart_planner/features/notifications/data/overdue_background_worker.dart';
import 'package:smart_planner/features/notifications/data/overdue_midnight_roll_worker.dart';
import 'package:smart_planner/features/notifications/data/task_daily_digest_worker.dart';
import 'package:workmanager/workmanager.dart';

/// Background jobs: overdue digest, midnight roll, day-status / home-widget refresh, task digests.
class BackgroundTaskService {
  BackgroundTaskService._();

  static const String taskCheckOverdue = 'check_overdue_tasks';
  static const String taskRefreshDayStatus = 'refresh_day_status';
  static const String taskRollOverdueMidnight = 'roll_overdue_midnight';
  static const String taskMorningDigest = 'morning_task_digest';
  static const String taskEveningDigest = 'evening_task_digest';

  static const String overdueUniqueName = 'smart_planner_background';
  static const String dayStatusUniqueName = 'smart_planner_day_status_refresh';
  static const String midnightRollUniqueName = 'smart_planner_midnight_roll';
  static const String morningDigestUniqueName = 'smart_planner_morning_digest';
  static const String eveningDigestUniqueName = 'smart_planner_evening_digest';

  static const int overdueDigestNotificationId = 77001;

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      overdueUniqueName,
      taskCheckOverdue,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    await Workmanager().registerPeriodicTask(
      dayStatusUniqueName,
      taskRefreshDayStatus,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    await scheduleNextMidnightRoll();
    await scheduleNextMorningDigest();
    await scheduleNextEveningDigest();
  }

  /// One-off ~00:05 local; rescheduled after each run from [OverdueMidnightRollWorker].
  static Future<void> scheduleNextMidnightRoll() async {
    if (kIsWeb) {
      return;
    }

    final Duration delay = _delayUntilNextLocalTime(
      DateTime.now(),
      hour: 0,
      minute: 5,
    );
    await Workmanager().registerOneOffTask(
      midnightRollUniqueName,
      taskRollOverdueMidnight,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  static Future<void> scheduleNextMorningDigest() async {
    if (kIsWeb) {
      return;
    }

    final Duration delay = _delayUntilNextLocalTime(
      DateTime.now(),
      hour: 8,
      minute: 0,
    );
    await Workmanager().registerOneOffTask(
      morningDigestUniqueName,
      taskMorningDigest,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  static Future<void> scheduleNextEveningDigest() async {
    if (kIsWeb) {
      return;
    }

    final Duration delay = _delayUntilNextLocalTime(
      DateTime.now(),
      hour: 19,
      minute: 0,
    );
    await Workmanager().registerOneOffTask(
      eveningDigestUniqueName,
      taskEveningDigest,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  static Duration _delayUntilNextLocalTime(
    DateTime now, {
    required int hour,
    required int minute,
  }) {
    final DateTime target = DateTime(now.year, now.month, now.day, hour, minute);
    final DateTime next =
        now.isBefore(target) ? target : target.add(const Duration(days: 1));
    return next.difference(now);
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(overdueUniqueName);
    await Workmanager().cancelByUniqueName(dayStatusUniqueName);
    await Workmanager().cancelByUniqueName(midnightRollUniqueName);
    await Workmanager().cancelByUniqueName(morningDigestUniqueName);
    await Workmanager().cancelByUniqueName(eveningDigestUniqueName);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (String taskName, Map<String, dynamic>? inputData) async {
      switch (taskName) {
        case BackgroundTaskService.taskCheckOverdue:
          return OverdueBackgroundWorker.run();
        case BackgroundTaskService.taskRefreshDayStatus:
          return DayStatusBackgroundSync.run();
        case BackgroundTaskService.taskRollOverdueMidnight:
          final bool ok = await OverdueMidnightRollWorker.run();
          await BackgroundTaskService.scheduleNextMidnightRoll();
          return ok;
        case BackgroundTaskService.taskMorningDigest:
          final bool morningOk = await TaskDailyDigestWorker.runMorning();
          await BackgroundTaskService.scheduleNextMorningDigest();
          return morningOk;
        case BackgroundTaskService.taskEveningDigest:
          final bool eveningOk = await TaskDailyDigestWorker.runEvening();
          await BackgroundTaskService.scheduleNextEveningDigest();
          return eveningOk;
        default:
          return false;
      }
    },
  );
}
