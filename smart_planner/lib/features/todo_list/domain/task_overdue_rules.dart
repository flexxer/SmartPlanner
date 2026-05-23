import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Бизнес-правила просрочки и переноса задач (PRD §3.2).
class TaskOverdueRules {
  TaskOverdueRules._();

  /// Учитывает перенос срока: увеличивает [Task.overdueCount] на число
  /// календарных дней между прежним и новым [Task.dueDate].
  ///
  /// Первое назначение [Task.dueDate] (когда срока ещё не было) счётчик не меняет.
  static void recordPostpone(Task task, DateTime newDueDate) {
    if (task.isCompleted) {
      return;
    }

    final DateTime? previousDue = task.dueDate;
    if (previousDue != null) {
      final int daysShift = AppDateUtils.calendarDaysBetween(
        previousDue,
        newDueDate,
      );
      if (daysShift > 0) {
        task.overdueCount += daysShift;
      }
    }

    task.dueDate = newDueDate;
  }

  /// Сценарий «перенести на завтра»: срок = следующий день от [referenceDate].
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
}
