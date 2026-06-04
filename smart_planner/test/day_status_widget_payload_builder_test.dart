import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload_builder.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('builds progress and task rows for widget', () {
    final DateTime now = DateTime(2026, 6, 2, 12);
    final Task active = Task.create(
      title: 'Slides',
      dueDate: now,
    );
    final Task done = Task.create(
      title: 'Report',
      dueDate: now,
      isCompleted: true,
    );
    final CalendarEvent event = CalendarEvent.createLocal(
      title: 'Stand-up',
      start: DateTime(2026, 6, 2, 15),
      end: DateTime(2026, 6, 2, 15, 30),
      calendarId: 'cal',
    );

    final DayStatusTodaySnapshot snapshot = DayStatusTodaySnapshot(
      activeTasks: <Task>[active],
      completedTasks: <Task>[done],
      backlogTasks: const <Task>[],
      overdueTasks: const <Task>[],
      calendarEvents: <CalendarEvent>[event],
      now: now,
    );

    final DayStatusWidgetPayload payload = DayStatusWidgetPayloadBuilder.build(
      snapshot,
      languageCode: 'en',
    );

    expect(payload.headerTitle, contains('1'));
    expect(payload.headerTitle, contains('2'));
    expect(payload.progressPercent, 50);
    expect(payload.taskRows, hasLength(1));
    expect(payload.taskRows.first, contains('Slides'));
    expect(payload.nowTitle, 'Stand-up');
    expect(payload.toWidgetData()['dw_now_label'], 'NOW');
  });

  test('hides progress when there are no tasks', () {
    final DateTime now = DateTime(2026, 6, 2, 12);
    final DayStatusTodaySnapshot snapshot = DayStatusTodaySnapshot(
      activeTasks: const <Task>[],
      completedTasks: const <Task>[],
      backlogTasks: const <Task>[],
      overdueTasks: const <Task>[],
      calendarEvents: const <CalendarEvent>[],
      now: now,
    );

    final DayStatusWidgetPayload payload = DayStatusWidgetPayloadBuilder.build(
      snapshot,
      languageCode: 'en',
    );

    expect(payload.progressPercent, -1);
  });
}
