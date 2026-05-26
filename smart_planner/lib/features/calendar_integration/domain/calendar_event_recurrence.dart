import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';

/// Helpers for reading recurrence metadata on [CalendarEvent].
class CalendarEventRecurrence {
  CalendarEventRecurrence._();

  static bool hasRepeatingRule(CalendarEvent event) {
    final RecurrenceRule? rule = event.recurrenceRule;
    return rule != null && rule.frequency != RecurrenceFrequency.none;
  }
}
