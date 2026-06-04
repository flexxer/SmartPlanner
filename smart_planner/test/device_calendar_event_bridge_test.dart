import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/data/device_calendar_event_bridge.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  test('maps weekly recurrence to plugin model', () {
    final dc.Event plugin = DeviceCalendarEventBridge.toPluginEvent(
      calendarId: 'cal1',
      title: 'Stand-up',
      start: DateTime(2026, 6, 2, 9, 0),
      end: DateTime(2026, 6, 2, 9, 30),
      recurrence: const RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
      ),
    );

    expect(plugin.recurrenceRule?.recurrenceFrequency,
        dc.RecurrenceFrequency.Weekly);
    expect(plugin.recurrenceRule?.interval, 2);
  });
}
