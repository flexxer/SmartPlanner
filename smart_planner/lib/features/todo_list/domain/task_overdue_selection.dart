import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Rules for which uncompleted tasks count as overdue and when the dashboard
/// should expose a separate [overdue tasks] list.
class TaskOverdueSelection {
  TaskOverdueSelection._();

  /// Uncompleted task with [Task.dueDate] strictly before [referenceDay].
  static bool isOverdueRelativeToDay(Task task, DateTime referenceDay) {
    if (task.isCompleted) {
      return false;
    }

    final DateTime? due = task.dueDate;
    if (due == null) {
      return false;
    }

    final DateTime dueDay = AppDateUtils.startOfDay(due);
    final DateTime day = AppDateUtils.startOfDay(referenceDay);
    return dueDay.isBefore(day);
  }

  /// Overdue list is shown only when the dashboard selected day is "today".
  static bool shouldExposeOverdueTasksForSelectedDay(
    DateTime selectedDate, {
    DateTime? today,
  }) {
    final DateTime referenceToday =
        AppDateUtils.startOfDay(today ?? DateTime.now());
    return AppDateUtils.isSameCalendarDay(selectedDate, referenceToday);
  }

  static List<Task> filterOverdueTasks(
    Iterable<Task> tasks,
    DateTime referenceDay,
  ) {
    return tasks
        .where((Task t) => isOverdueRelativeToDay(t, referenceDay))
        .toList(growable: false);
  }
}
