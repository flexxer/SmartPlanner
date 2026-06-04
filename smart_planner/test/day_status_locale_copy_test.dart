import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/domain/day_status_locale_copy.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  test('notification content uses locale strings', () {
    final DateTime now = DateTime(2026, 6, 1, 12);
    final Task active = Task.create(
      title: 'Report',
      calendarId: 'cal',
      dueDate: now,
    );
    final Task done = Task.create(
      title: 'Done',
      calendarId: 'cal',
      isCompleted: true,
    );

    final DayStatusTodaySnapshot snapshot = DayStatusTodaySnapshot(
      activeTasks: <Task>[active],
      completedTasks: <Task>[done],
      backlogTasks: const <Task>[],
      overdueTasks: const <Task>[],
      calendarEvents: const <CalendarEvent>[],
      now: now,
    );

    final content = DayStatusLocaleCopy.notificationContent(
      snapshot: snapshot,
      languageCode: 'ru',
    );

    expect(content.title, contains('1'));
    expect(content.title, contains('2'));
    expect(content.body, contains('событий'));
  });

  test('widget payload includes footer and now label', () {
    final DateTime now = DateTime(2026, 6, 1, 12);
    final Task active = Task.create(
      title: 'Report',
      dueDate: now,
    );

    final DayStatusTodaySnapshot snapshot = DayStatusTodaySnapshot(
      activeTasks: <Task>[active],
      completedTasks: const <Task>[],
      backlogTasks: const <Task>[],
      overdueTasks: const <Task>[],
      calendarEvents: const <CalendarEvent>[],
      now: now,
    );

    final payload = DayStatusLocaleCopy.widgetPayload(
      snapshot: snapshot,
      languageCode: 'ru',
    );

    expect(payload.nowLabel, 'СЕЙЧАС');
    expect(payload.footerText, contains('Открыть'));
  });
}
