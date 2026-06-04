import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_selection.dart';

/// Overdue-day calculation and due-date postpone helpers (PRD §3.2).
class TaskOverdueRules {
  TaskOverdueRules._();

  /// Calendar days past [Task.dueDate] relative to [now] (start-of-day).
  /// Returns `0` when completed, undated, or not yet overdue.
  static int dynamicOverdueDays(Task task, {DateTime? now}) {
    if (task.isCompleted) {
      return 0;
    }

    final DateTime? due = task.dueDate;
    if (due == null) {
      return 0;
    }

    final DateTime today = AppDateUtils.startOfDay(now ?? DateTime.now());
    final DateTime dueDay = AppDateUtils.startOfDay(due);
    if (!dueDay.isBefore(today)) {
      return 0;
    }

    return AppDateUtils.calendarDaysBetween(dueDay, today);
  }

  /// Sets [Task.dueDate] to [newDueDate]; overdue days are derived on read.
  static void recordPostpone(Task task, DateTime newDueDate) {
    if (task.isCompleted) {
      return;
    }

    task.dueDate = AppDateUtils.startOfDay(newDueDate);
    task.markUpdated();
  }

  /// Due date = day after [referenceDate] (start-of-day).
  static void postponeToNextDay(
    Task task, {
    DateTime? referenceDate,
  }) {
    final DateTime base = referenceDate ?? DateTime.now();
    final DateTime tomorrow = AppDateUtils.startOfDay(base).add(
      const Duration(days: 1),
    );
    recordPostpone(task, tomorrow);
  }

  /// Midnight roll: moves an overdue task onto [referenceDay] (start-of-day).
  static void rollToToday(
    Task task, {
    required DateTime referenceDay,
  }) {
    if (!TaskOverdueSelection.isOverdueRelativeToDay(task, referenceDay)) {
      return;
    }
    recordPostpone(task, AppDateUtils.startOfDay(referenceDay));
  }
}
