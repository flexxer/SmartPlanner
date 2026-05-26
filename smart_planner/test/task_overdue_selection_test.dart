import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_rules.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_selection.dart';

void main() {
  final DateTime today = AppDateUtils.startOfDay(DateTime(2026, 5, 23));
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateTime tomorrow = today.add(const Duration(days: 1));

  group('TaskOverdueSelection.isOverdueRelativeToDay', () {
    test('task due yesterday is overdue relative to today', () {
      final Task task = Task.create(title: 'Late', dueDate: yesterday);
      expect(
        TaskOverdueSelection.isOverdueRelativeToDay(task, today),
        isTrue,
      );
      expect(
        TaskOverdueRules.dynamicOverdueDays(task, now: today),
        1,
      );
    });

    test('task due today is not overdue relative to today', () {
      final Task task = Task.create(title: 'Due today', dueDate: today);
      expect(
        TaskOverdueSelection.isOverdueRelativeToDay(task, today),
        isFalse,
      );
    });

    test('task due tomorrow is not overdue relative to today', () {
      final Task task = Task.create(title: 'Future', dueDate: tomorrow);
      expect(
        TaskOverdueSelection.isOverdueRelativeToDay(task, today),
        isFalse,
      );
    });

    test('completed task with past due date is not overdue', () {
      final Task task = Task.create(
        title: 'Done',
        dueDate: yesterday,
        isCompleted: true,
      );
      expect(
        TaskOverdueSelection.isOverdueRelativeToDay(task, today),
        isFalse,
      );
    });

    test('task without due date is not overdue', () {
      final Task task = Task.create(title: 'Inbox');
      expect(
        TaskOverdueSelection.isOverdueRelativeToDay(task, today),
        isFalse,
      );
    });
  });

  group('TaskOverdueSelection.shouldExposeOverdueTasksForSelectedDay', () {
    test('returns true when selected day is today', () {
      expect(
        TaskOverdueSelection.shouldExposeOverdueTasksForSelectedDay(
          today,
          today: today,
        ),
        isTrue,
      );
    });

    test('returns false when selected day is not today', () {
      expect(
        TaskOverdueSelection.shouldExposeOverdueTasksForSelectedDay(
          tomorrow,
          today: today,
        ),
        isFalse,
      );
      expect(
        TaskOverdueSelection.shouldExposeOverdueTasksForSelectedDay(
          yesterday,
          today: today,
        ),
        isFalse,
      );
    });
  });

  group('TaskOverdueSelection.filterOverdueTasks', () {
    test('keeps only uncompleted tasks due before reference day', () {
      final List<Task> tasks = <Task>[
        Task.create(title: 'Overdue', dueDate: yesterday),
        Task.create(title: 'Due today', dueDate: today),
        Task.create(title: 'Future', dueDate: tomorrow),
        Task.create(title: 'Inbox'),
        Task.create(
          title: 'Done late',
          dueDate: yesterday,
          isCompleted: true,
        ),
      ];

      final List<Task> overdue =
          TaskOverdueSelection.filterOverdueTasks(tasks, today);

      expect(overdue, hasLength(1));
      expect(overdue.single.title, 'Overdue');
    });
  });
}
