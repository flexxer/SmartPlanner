import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_date_visibility.dart';

void main() {
  test('recurring weekly task appears on matching weekdays', () {
    final DateTime due = DateTime(2026, 6, 2); // Monday
    final Task task = Task.create(
      title: 'Weekly',
      dueDate: due,
      calendarId: 'cal',
    )..recurrenceRule = const RecurrenceRule(frequency: RecurrenceFrequency.weekly);

    expect(
      TaskDateVisibility.isVisibleOnDate(task, DateTime(2026, 6, 2)),
      isTrue,
    );
    expect(
      TaskDateVisibility.isVisibleOnDate(task, DateTime(2026, 6, 9)),
      isTrue,
    );
    expect(
      TaskDateVisibility.isVisibleOnDate(task, DateTime(2026, 6, 3)),
      isFalse,
    );
  });
}
