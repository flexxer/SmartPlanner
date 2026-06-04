import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_rules.dart';

void main() {
  final DateTime today = AppDateUtils.startOfDay(DateTime(2026, 5, 23));
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateTime twoDaysAgo = today.subtract(const Duration(days: 2));

  group('TaskOverdueRules.dynamicOverdueDays', () {
    test('returns 0 when completed', () {
      final Task task = Task.create(
        title: 'Done',
        dueDate: twoDaysAgo,
        isCompleted: true,
      );
      expect(
        TaskOverdueRules.dynamicOverdueDays(task, now: today),
        0,
      );
    });

    test('returns 0 when due date is null', () {
      final Task task = Task.create(title: 'Inbox');
      expect(
        TaskOverdueRules.dynamicOverdueDays(task, now: today),
        0,
      );
    });

    test('returns 0 when due date is today or later', () {
      expect(
        TaskOverdueRules.dynamicOverdueDays(
          Task.create(title: 'Today', dueDate: today),
          now: today,
        ),
        0,
      );
      expect(
        TaskOverdueRules.dynamicOverdueDays(
          Task.create(
            title: 'Future',
            dueDate: today.add(const Duration(days: 1)),
          ),
          now: today,
        ),
        0,
      );
    });

    test('returns calendar days since due date when overdue', () {
      final Task oneDay = Task.create(title: 'Late', dueDate: yesterday);
      expect(
        TaskOverdueRules.dynamicOverdueDays(oneDay, now: today),
        1,
      );

      final Task twoDays = Task.create(title: 'Very late', dueDate: twoDaysAgo);
      expect(
        TaskOverdueRules.dynamicOverdueDays(twoDays, now: today),
        2,
      );
    });

    test('Task.dynamicOverdueDays getter matches rules', () {
      final Task task = Task.create(title: 'Late', dueDate: twoDaysAgo);
      expect(
        task.dynamicOverdueDays,
        TaskOverdueRules.dynamicOverdueDays(task, now: DateTime.now()),
      );
    });
  });

  group('TaskOverdueRules.recordPostpone', () {
    test('updates due date without persisting a manual overdue counter', () {
      final Task task = Task.create(title: 'Late', dueDate: twoDaysAgo);
      TaskOverdueRules.recordPostpone(task, today);

      expect(task.dueDate, today);
      expect(
        TaskOverdueRules.dynamicOverdueDays(task, now: today),
        0,
      );
    });

    test('postponeToNextDay sets due date to tomorrow', () {
      final Task task = Task.create(title: 'A', dueDate: today);
      TaskOverdueRules.postponeToNextDay(task, referenceDate: today);

      expect(
        task.dueDate,
        today.add(const Duration(days: 1)),
      );
      expect(
        TaskOverdueRules.dynamicOverdueDays(task, now: today),
        0,
      );
    });

    test('rollToToday moves overdue task onto reference day', () {
      final Task task = Task.create(title: 'Late', dueDate: twoDaysAgo);
      TaskOverdueRules.rollToToday(task, referenceDay: today);

      expect(task.dueDate, today);
      expect(
        TaskOverdueRules.dynamicOverdueDays(task, now: today),
        0,
      );
    });

    test('rollToToday is no-op when task is not overdue', () {
      final Task task = Task.create(title: 'On time', dueDate: today);
      TaskOverdueRules.rollToToday(task, referenceDay: today);

      expect(task.dueDate, today);
    });
  });

  group('auto-roll preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('defaults to enabled', () async {
      final NotificationPreferencesRepository prefs =
          NotificationPreferencesRepository();
      expect(await prefs.isAutoRollOverdueAtMidnightEnabled(), isTrue);
    });

    test('last roll day key round-trips', () async {
      final NotificationPreferencesRepository prefs =
          NotificationPreferencesRepository();
      final int key = AppDateUtils.dayKeyMs(today);
      await prefs.setLastOverdueMidnightRollDayKey(key);
      expect(await prefs.getLastOverdueMidnightRollDayKey(), key);
    });
  });
}
