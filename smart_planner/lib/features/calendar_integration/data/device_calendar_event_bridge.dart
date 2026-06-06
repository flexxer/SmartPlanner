import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart'
    as domain;
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:timezone/timezone.dart' as tz;

/// Maps domain [CalendarEvent] fields to [device_calendar] plugin models.
abstract final class DeviceCalendarEventBridge {
  DeviceCalendarEventBridge._();

  static dc.Event toPluginEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? deviceEventId,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    bool allDay = false,
  }) {
    final dc.Event event = dc.Event(
      calendarId,
      eventId: deviceEventId,
      title: title,
      start: _toTz(start),
      end: _toTz(end),
      allDay: allDay,
      recurrenceRule: _toPluginRecurrence(recurrence),
      reminders: _toPluginReminders(reminderMinutesBefore),
    );
    return event;
  }

  static tz.TZDateTime _toTz(DateTime value) =>
      tz.TZDateTime.from(value, tz.local);

  static List<dc.Reminder>? _toPluginReminders(int? minutesBefore) {
    if (minutesBefore == null) {
      return null;
    }
    return <dc.Reminder>[dc.Reminder(minutes: minutesBefore)];
  }

  static dc.RecurrenceRule? _toPluginRecurrence(RecurrenceRule? rule) {
    if (rule == null || rule.frequency == domain.RecurrenceFrequency.none) {
      return null;
    }

    final dc.RecurrenceFrequency? frequency = switch (rule.frequency) {
      domain.RecurrenceFrequency.daily => dc.RecurrenceFrequency.Daily,
      domain.RecurrenceFrequency.weekly => dc.RecurrenceFrequency.Weekly,
      domain.RecurrenceFrequency.monthly => dc.RecurrenceFrequency.Monthly,
      domain.RecurrenceFrequency.yearly => dc.RecurrenceFrequency.Yearly,
      domain.RecurrenceFrequency.none => null,
    };
    if (frequency == null) {
      return null;
    }

    return dc.RecurrenceRule(
      frequency,
      interval: rule.interval,
      endDate: rule.until,
    );
  }
}
