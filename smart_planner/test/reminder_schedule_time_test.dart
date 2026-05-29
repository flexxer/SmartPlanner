import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/notifications/domain/reminder_schedule_time.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

void main() {
  group('ReminderScheduleTime', () {
    test('task uses reminderAt', () {
      final Task task = Task.create(
        title: 'Report',
        calendarId: 'cal',
        reminderAt: DateTime(2026, 5, 26, 14, 30),
      );

      expect(
        ReminderScheduleTime.fireAtForTask(task),
        DateTime(2026, 5, 26, 14, 30),
      );
    });

    test('task without reminderAt does not schedule', () {
      final Task task = Task.create(
        title: 'Backlog',
        calendarId: 'cal',
      );

      expect(ReminderScheduleTime.fireAtForTask(task), isNull);
    });

    test('completed task does not schedule', () {
      final Task task = Task.create(
        title: 'Done',
        calendarId: 'cal',
        reminderAt: DateTime(2026, 5, 26, 10, 0),
        isCompleted: true,
      );

      expect(ReminderScheduleTime.fireAtForTask(task), isNull);
    });

    test('event fire time is start minus offset', () {
      final CalendarEvent event = CalendarEvent.createLocal(
        title: 'Stand-up',
        start: DateTime(2026, 5, 26, 10, 0),
        end: DateTime(2026, 5, 26, 10, 30),
        calendarId: 'cal',
      )..reminderMinutesBefore = 15;

      final DateTime? fireAt = ReminderScheduleTime.fireAtForEvent(event);

      expect(fireAt, DateTime(2026, 5, 26, 9, 45));
    });
  });
}
