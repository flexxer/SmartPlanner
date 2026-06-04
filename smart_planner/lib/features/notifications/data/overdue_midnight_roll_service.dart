import 'package:smart_planner/core/app_initializer.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Result of [OverdueMidnightRollService.runIfNeeded].
enum OverdueMidnightRollOutcome {
  skippedDisabled,
  skippedAlreadyRolled,
  nothingToRoll,
  rolled,
}

/// Rolls overdue uncompleted tasks to today once per local calendar day.
class OverdueMidnightRollService {
  OverdueMidnightRollService({
    NotificationPreferencesRepository? preferences,
    TodoRepository? todoRepository,
    ItemReminderScheduler? reminderScheduler,
  })  : _preferences = preferences ?? NotificationPreferencesRepository(),
        _todoRepository = todoRepository ?? TodoRepository(),
        _reminderScheduler =
            reminderScheduler ?? AppInitializer.itemReminders;

  final NotificationPreferencesRepository _preferences;
  final TodoRepository _todoRepository;
  final ItemReminderScheduler _reminderScheduler;

  /// Applies midnight roll when enabled and not yet run for [now]'s calendar day.
  Future<({OverdueMidnightRollOutcome outcome, int rolledCount})> runIfNeeded({
    DateTime? now,
  }) async {
    final DateTime today = AppDateUtils.startOfDay(now ?? DateTime.now());
    final int todayKey = AppDateUtils.dayKeyMs(today);

    if (!await _preferences.isAutoRollOverdueAtMidnightEnabled()) {
      return (outcome: OverdueMidnightRollOutcome.skippedDisabled, rolledCount: 0);
    }

    final int? lastKey = await _preferences.getLastOverdueMidnightRollDayKey();
    if (lastKey == todayKey) {
      return (
        outcome: OverdueMidnightRollOutcome.skippedAlreadyRolled,
        rolledCount: 0,
      );
    }

    final List<Task> overdueBeforeRoll =
        await _todoRepository.getOverdueUncompletedTasks(referenceDay: today);
    if (overdueBeforeRoll.isEmpty) {
      await _preferences.setLastOverdueMidnightRollDayKey(todayKey);
      return (outcome: OverdueMidnightRollOutcome.nothingToRoll, rolledCount: 0);
    }

    final int rolled = await _todoRepository.rollOverdueUncompletedToToday(
      referenceDay: today,
    );
    await _preferences.setLastOverdueMidnightRollDayKey(todayKey);

    for (final Task task in overdueBeforeRoll) {
      try {
        final Task? updated = await _todoRepository.getTaskById(task.id);
        if (updated != null) {
          await _reminderScheduler.syncTask(updated);
        }
      } on Object {
        //
      }
    }

    return (outcome: OverdueMidnightRollOutcome.rolled, rolledCount: rolled);
  }
}
