import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_day_markers_builder.dart';

void main() {
  final DateTime monday = DateTime(2026, 5, 18);

  test('marks days with calendar events and task keys', () {
    final DateTime tuesday = monday.add(const Duration(days: 1));
    final int mondayKey = AppDateUtils.dayKeyMs(monday);
    final int tuesdayKey = AppDateUtils.dayKeyMs(tuesday);

    final Map<int, DayActivityMarker> markers = DashboardDayMarkersBuilder.build(
      rangeStart: monday,
      rangeEnd: monday.add(const Duration(days: 2)),
      taskDayKeys: <int>{tuesdayKey},
      events: <CalendarEvent>[
        CalendarEvent.fromDevice(
          deviceEventId: 'e1',
          title: 'Meeting',
          start: monday.add(const Duration(hours: 10)),
          end: monday.add(const Duration(hours: 11)),
          calendarId: 'cal1',
          colorValue: 0xFFE91E63,
        ),
      ],
    );

    expect(markers[mondayKey]!.hasCalendarEvents, isTrue);
    expect(markers[mondayKey]!.calendarColorValue, 0xFFE91E63);
    expect(markers[mondayKey]!.hasLocalTasks, isFalse);
    expect(markers[tuesdayKey]!.hasLocalTasks, isTrue);
    expect(markers[tuesdayKey]!.hasCalendarEvents, isFalse);
  });
}
