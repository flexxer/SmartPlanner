import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/domain/task_reopen.dart';

void main() {
  test('fromCompleted copies fields and resets completion state', () {
    final Task source = Task.create(
      title: 'Report',
      description: 'Q1',
      dueDate: DateTime(2026, 1, 10),
      priority: TaskPriority.high,
      isCompleted: true,
    );
    source.overdueCount = 3;

    final DateTime newDue = DateTime(2026, 5, 25, 14, 30);
    final Task reopened = TaskReopen.fromCompleted(source, dueDate: newDue);

    expect(reopened.title, 'Report');
    expect(reopened.description, 'Q1');
    expect(reopened.priority, TaskPriority.high);
    expect(reopened.isCompleted, isFalse);
    expect(reopened.overdueCount, 0);
    expect(
      reopened.dueDate,
      AppDateUtils.startOfDay(newDue),
    );
    expect(reopened.parentTaskId, isNull);
  });
}
