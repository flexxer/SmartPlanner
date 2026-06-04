import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';

void main() {
  test('createLocal sets EventSource.local and updatedAt', () {
    final CalendarEvent event = CalendarEvent.createLocal(
      title: 'Standup',
      start: DateTime(2026, 6, 1, 10),
      end: DateTime(2026, 6, 1, 10, 30),
      calendarId: 'cal_1',
    );

    expect(event.source, EventSource.local);
    expect(event.updatedAt, isNotNull);
    expect(event.deviceEventId.startsWith('local_'), isTrue);
  });

  test('fromDevice sets EventSource.device and updatedAt', () {
    final CalendarEvent event = CalendarEvent.fromDevice(
      deviceEventId: 'dev_42',
      title: 'Meeting',
      start: DateTime(2026, 6, 1, 14),
      end: DateTime(2026, 6, 1, 15),
      calendarId: 'cal_1',
      colorValue: 0xFF000000,
    );

    expect(event.source, EventSource.device);
    expect(event.updatedAt, isNotNull);
  });
}
