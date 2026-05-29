import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/core/localization/app_locales.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_builder.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_content.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
  });

  Future<void> pumpLocalizedApp(WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.fallback,
        useOnlyLangCode: true,
        child: Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DayStatusNotificationBuilder', () {
    testWidgets('builds task summary title', (WidgetTester tester) async {
      await pumpLocalizedApp(tester);

      final Task active = Task()..title = 'A';
      final Task done = Task()
        ..title = 'B'
        ..isCompleted = true;

      final DayStatusNotificationContent content =
          DayStatusNotificationBuilder.build(
        activeTasks: <Task>[active],
        completedTasks: <Task>[done, done],
        backlogTasks: const <Task>[],
        calendarEvents: const <CalendarEvent>[],
        now: DateTime(2026, 5, 25, 12),
      );

      expect(content.title, contains('2'));
      expect(content.title, contains('3'));
      expect(content.body, isNotEmpty);
    });

    testWidgets('prefers current event over next', (WidgetTester tester) async {
      await pumpLocalizedApp(tester);

      final CalendarEvent current = CalendarEvent()
        ..title = 'Rehearsal'
        ..start = DateTime(2026, 5, 25, 11)
        ..end = DateTime(2026, 5, 25, 19)
        ..calendarId = 'c1';
      final CalendarEvent later = CalendarEvent()
        ..title = 'Dinner'
        ..start = DateTime(2026, 5, 25, 20)
        ..end = DateTime(2026, 5, 25, 21)
        ..calendarId = 'c1';

      final DayStatusNotificationContent content =
          DayStatusNotificationBuilder.build(
        activeTasks: const <Task>[],
        completedTasks: const <Task>[],
        backlogTasks: const <Task>[],
        calendarEvents: <CalendarEvent>[current, later],
        now: DateTime(2026, 5, 25, 12),
      );

      expect(content.body, contains('Rehearsal'));
      expect(content.body, isNot(contains('Dinner')));
    });

    testWidgets('shows next event when none is current',
        (WidgetTester tester) async {
      await pumpLocalizedApp(tester);

      final CalendarEvent next = CalendarEvent()
        ..title = 'Stand-up'
        ..start = DateTime(2026, 5, 25, 15)
        ..end = DateTime(2026, 5, 25, 15, 30)
        ..calendarId = 'c1';

      final DayStatusNotificationContent content =
          DayStatusNotificationBuilder.build(
        activeTasks: const <Task>[],
        completedTasks: const <Task>[],
        backlogTasks: const <Task>[],
        calendarEvents: <CalendarEvent>[next],
        now: DateTime(2026, 5, 25, 12),
      );

      expect(content.body, contains('Stand-up'));
    });

    testWidgets('appends backlog line when undated tasks exist',
        (WidgetTester tester) async {
      await pumpLocalizedApp(tester);

      final DayStatusNotificationContent content =
          DayStatusNotificationBuilder.build(
        activeTasks: const <Task>[],
        completedTasks: const <Task>[],
        backlogTasks: <Task>[Task()..title = 'Someday', Task()..title = 'Later'],
        calendarEvents: const <CalendarEvent>[],
        now: DateTime(2026, 5, 25, 12),
      );

      expect(content.body, contains('2'));
      expect(content.body, contains('Backlog'));
    });

    testWidgets('omits task count when there are no tasks',
        (WidgetTester tester) async {
      await pumpLocalizedApp(tester);

      final DayStatusNotificationContent content =
          DayStatusNotificationBuilder.build(
        activeTasks: const <Task>[],
        completedTasks: const <Task>[],
        backlogTasks: const <Task>[],
        calendarEvents: const <CalendarEvent>[],
        now: DateTime(2026, 5, 25, 12),
      );

      expect(content.title, isNot(contains('0')));
      expect(content.title, isNot(contains('/')));
      expect(content.body, isNotEmpty);
    });
  });
}
