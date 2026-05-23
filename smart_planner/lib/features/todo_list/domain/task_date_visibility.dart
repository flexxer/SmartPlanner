import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Какие невыполненные задачи показывать на выбранный календарный день.
class TaskDateVisibility {
  TaskDateVisibility._();

  /// Задача без срока видна только на «сегодня»; со сроком — в день срока
  /// и на каждый последующий день до выполнения (перенос просрочки).
  static bool isVisibleOnDate(Task task, DateTime selectedDate) {
    if (task.isCompleted) {
      return false;
    }

    final DateTime day = AppDateUtils.startOfDay(selectedDate);
    final DateTime today = AppDateUtils.startOfDay(DateTime.now());
    final DateTime? due = task.dueDate;

    if (due == null) {
      return AppDateUtils.isSameCalendarDay(day, today);
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
