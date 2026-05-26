import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_date_visibility.dart';

void main() {
  final DateTime today = AppDateUtils.startOfDay(DateTime.now());

  test('task due today is visible on today', () {
    final Task task = Task.create(title: 'A', dueDate: today);
    expect(TaskDateVisibility.isVisibleOnDate(task, today), isTrue);
  });

  test('task due tomorrow is not visible on today', () {
    final Task task = Task.create(
      title: 'A',
      dueDate: today.add(const Duration(days: 1)),
    );
    expect(TaskDateVisibility.isVisibleOnDate(task, today), isFalse);
  });

  test('overdue task is visible on today', () {
    final Task task = Task.create(
      title: 'A',
      dueDate: today.subtract(const Duration(days: 3)),
    );
    expect(TaskDateVisibility.isVisibleOnDate(task, today), isTrue);
  });

  test('task without due date is not shown on a calendar day', () {
    final Task task = Task.create(title: 'Inbox');
    expect(TaskDateVisibility.isVisibleOnDate(task, today), isFalse);
    expect(
      TaskDateVisibility.isVisibleOnDate(
        task,
        today.add(const Duration(days: 1)),
      ),
      isFalse,
    );
  });

  test('taskDayKeysWithVisibleTasksInRange includes due and overdue days', () {
    final DateTime today = AppDateUtils.startOfDay(DateTime(2026, 5, 23));
    final DateTime overdue = today.subtract(const Duration(days: 2));
    final Task overdueTask = Task.create(title: 'Late', dueDate: overdue);
    final Task futureTask = Task.create(
      title: 'Future',
      dueDate: today.add(const Duration(days: 4)),
    );

    final Set<int> keys = TaskDateVisibility.taskDayKeysWithVisibleTasksInRange(
      tasks: <Task>[overdueTask, futureTask],
      rangeStart: today.subtract(const Duration(days: 7)),
      rangeEnd: today.add(const Duration(days: 7)),
    );

    expect(keys, contains(AppDateUtils.dayKeyMs(overdue)));
    expect(keys, contains(AppDateUtils.dayKeyMs(today)));
    expect(keys, contains(AppDateUtils.dayKeyMs(today.add(const Duration(days: 4)))));
  });

  test('task due on selected future day is visible that day', () {
    final DateTime future = today.add(const Duration(days: 5));
    final Task task = Task.create(title: 'A', dueDate: future);
    expect(TaskDateVisibility.isVisibleOnDate(task, future), isTrue);
    expect(TaskDateVisibility.isVisibleOnDate(task, today), isFalse);
  });
}
