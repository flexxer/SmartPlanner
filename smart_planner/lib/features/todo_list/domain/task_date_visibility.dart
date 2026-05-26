import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Какие невыполненные задачи показывать на выбранный календарный день.
class TaskDateVisibility {
  TaskDateVisibility._();

  /// Undated tasks are shown in the dashboard «Без срока» section, not per day.
  /// Dated tasks appear on the due day and every following day until completed.
  /// Completed root tasks shown at the bottom of the dashboard day list.
  static bool isCompletedVisibleOnDate(Task task, DateTime selectedDate) {
    if (!task.isCompleted) {
      return false;
    }

    final DateTime day = AppDateUtils.startOfDay(selectedDate);
    final DateTime? due = task.dueDate;

    if (due == null) {
      final DateTime? updated = task.updatedAt;
      if (updated == null) {
        return AppDateUtils.isSameCalendarDay(
          day,
          AppDateUtils.startOfDay(DateTime.now()),
        );
      }
      return AppDateUtils.isSameCalendarDay(
        AppDateUtils.startOfDay(updated),
        day,
      );
    }

    return AppDateUtils.isSameCalendarDay(AppDateUtils.startOfDay(due), day);
  }

  static bool isVisibleOnDate(Task task, DateTime selectedDate) {
    if (task.isCompleted) {
      return false;
    }

    final DateTime day = AppDateUtils.startOfDay(selectedDate);
    final DateTime? due = task.dueDate;

    if (due == null) {
      return false;
    }

    final DateTime dueDay = AppDateUtils.startOfDay(due);
    if (dueDay.isAfter(day)) {
      return false;
    }

    return true;
  }

  /// Root uncompleted tasks visible on any day in [rangeStart]…[rangeEnd] (inclusive).
  static Set<int> taskDayKeysWithVisibleTasksInRange({
    required List<Task> tasks,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final Set<int> keys = <int>{};
    final DateTime start = AppDateUtils.startOfDay(rangeStart);
    final DateTime end = AppDateUtils.startOfDay(rangeEnd);
    final DateTime today = AppDateUtils.startOfDay(DateTime.now());

    for (final Task task in tasks) {
      if (!TaskHierarchy.isRoot(task) || task.isCompleted) {
        continue;
      }

      final DateTime? due = task.dueDate;
      if (due == null) {
        if (!today.isBefore(start) && !today.isAfter(end)) {
          keys.add(AppDateUtils.dayKeyMs(today));
        }
        continue;
      }

      DateTime day = AppDateUtils.startOfDay(due);
      if (day.isBefore(start)) {
        day = start;
      }
      while (!day.isAfter(end)) {
        keys.add(AppDateUtils.dayKeyMs(day));
        day = day.add(const Duration(days: 1));
      }
    }

    return keys;
  }
}
