import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';

void main() {
  group('RecurrenceEvaluator.shouldShowEventOnDate', () {
    test('daily every 3 days from anchor', () {
      final CalendarEvent event = _event(
        start: DateTime(2026, 1, 1, 9),
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        ),
      );

      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 1)),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 4)),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 7)),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 2)),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 3)),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2025, 12, 31)),
        isFalse,
      );
    });

    test('first working day of month when the 1st is Saturday', () {
      // August 1, 2026 is Saturday -> first working day is Monday, August 3.
      final CalendarEvent event = _event(
        start: DateTime(2026, 8, 1, 10),
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          weekOfMonth: 1,
          onlyWorkingDays: true,
        ),
      );

      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 8, 1),
        ),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 8, 2),
        ),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 8, 3),
        ),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 8, 4),
        ),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 9, 1),
        ),
        isTrue,
      );
    });

    test('first working day of month when the 1st is Sunday', () {
      // November 1, 2026 is Sunday -> first working day is Monday, November 2.
      final CalendarEvent event = _event(
        start: DateTime(2026, 11, 1, 10),
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          weekOfMonth: 1,
          onlyWorkingDays: true,
        ),
      );

      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 11, 1),
        ),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 11, 2),
        ),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 11, 3),
        ),
        isFalse,
      );
    });

    test('second Thursday of each month', () {
      // March 2026: first Thursday = 5th, second Thursday = 12th.
      final CalendarEvent event = _event(
        start: DateTime(2026, 3, 12, 14),
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          weekOfMonth: 2,
          daysOfWeek: <int>[DateTime.thursday],
        ),
      );

      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 3, 5),
        ),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 3, 12),
        ),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 3, 19),
        ),
        isFalse,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 4, 9),
        ),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 4, 2),
        ),
        isFalse,
      );
    });

    test('returns false after until date', () {
      final CalendarEvent event = _event(
        start: DateTime(2026, 1, 1),
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          until: DateTime(2026, 1, 10),
        ),
      );

      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 10)),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(event, DateTime(2026, 1, 11)),
        isFalse,
      );
    });

    test('non-recurring event only on anchor day', () {
      final CalendarEvent event = _event(
        start: DateTime(2026, 5, 15, 11),
        rule: null,
      );

      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 5, 15),
        ),
        isTrue,
      );
      expect(
        RecurrenceEvaluator.shouldShowEventOnDate(
          event,
          DateTime(2026, 5, 16),
        ),
        isFalse,
      );
    });
  });
}

CalendarEvent _event({
  required DateTime start,
  RecurrenceRule? rule,
}) {
  return CalendarEvent.fromDevice(
    deviceEventId: 'eval-test',
    title: 'Eval test',
    start: start,
    end: start.add(const Duration(hours: 1)),
    calendarId: 'cal-1',
    colorValue: 0xFF000000,
    recurrenceRule: rule,
  );
}
