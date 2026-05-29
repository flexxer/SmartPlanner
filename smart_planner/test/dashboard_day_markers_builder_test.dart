import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_day_markers_builder.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

void main() {
  final DateTime monday = DateTime(2026, 5, 18);

  test('counts events and timed tasks per day', () {
    final DateTime tuesday = monday.add(const Duration(days: 1));
    final int mondayKey = AppDateUtils.dayKeyMs(monday);
    final int tuesdayKey = AppDateUtils.dayKeyMs(tuesday);

    final Task tuesdayTask = Task.create(
      title: 'Due Tuesday',
      dueDate: tuesday,
    )..id = 1;

    final Task mondayReminder = Task.create(
      title: 'Reminder Monday',
      dueDate: monday.add(const Duration(days: 3)),
      reminderAt: monday.add(const Duration(hours: 9)),
    )..id = 2;

    final Map<int, DayActivityMarker> markers = DashboardDayMarkersBuilder.build(
      rangeStart: monday,
      rangeEnd: monday.add(const Duration(days: 2)),
      tasks: <Task>[tuesdayTask, mondayReminder],
      events: <CalendarEvent>[
        CalendarEvent.fromDevice(
          deviceEventId: 'e1',
          title: 'Meeting',
          start: monday.add(const Duration(hours: 10)),
          end: monday.add(const Duration(hours: 11)),
          calendarId: 'cal1',
          colorValue: 0xFFE91E63,
        ),
        CalendarEvent.fromDevice(
          deviceEventId: 'e2',
          title: 'Standup',
          start: monday.add(const Duration(hours: 14)),
          end: monday.add(const Duration(hours: 14, minutes: 30)),
          calendarId: 'cal1',
          colorValue: 0xFFE91E63,
        ),
      ],
    );

    expect(markers[mondayKey]!.eventCount, 2);
    expect(markers[mondayKey]!.timedTaskCount, 1);
    expect(markers[mondayKey]!.stripBadgeLabel, '2+1');
    expect(markers[tuesdayKey]!.eventCount, 0);
    expect(markers[tuesdayKey]!.timedTaskCount, 1);
    expect(markers[tuesdayKey]!.stripBadgeLabel, '1');
    expect(markers[tuesdayKey]!.hasLocalTasks, isTrue);
  });
}
