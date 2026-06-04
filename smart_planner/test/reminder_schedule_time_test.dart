import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
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

    test('recurring event fire time resolves next occurrence', () {
      final DateTime now = DateTime.now();
      final DateTime yesterdayAtTen = DateTime(
        now.year,
        now.month,
        now.day - 1,
        10,
      );
      final CalendarEvent event = CalendarEvent.createLocal(
        title: 'Daily sync',
        start: yesterdayAtTen,
        end: yesterdayAtTen.add(const Duration(minutes: 30)),
        calendarId: 'cal',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        ),
      )..reminderMinutesBefore = 15;

      final DateTime? fireAt = ReminderScheduleTime.fireAtForEvent(event);
      expect(fireAt, isNotNull);
      expect(fireAt!.isAfter(now.subtract(const Duration(minutes: 1))), isTrue);
    });
  });
}
