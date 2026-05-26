import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';

void main() {
  test('round-trips weekly rule with daysOfWeek and until', () {
    final DateTime until = DateTime(2026, 12, 31, 23, 59);
    const RecurrenceRule original = RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      daysOfWeek: <int>[1, 3, 5],
      onlyWorkingDays: true,
      until: null,
    );
    final RecurrenceRule withUntil = RecurrenceRule(
      frequency: original.frequency,
      interval: original.interval,
      daysOfWeek: original.daysOfWeek,
      onlyWorkingDays: original.onlyWorkingDays,
      until: until,
    );

    final RecurrenceRule restored =
        RecurrenceRule.fromJsonString(withUntil.toJsonString());

    expect(restored.frequency, RecurrenceFrequency.weekly);
    expect(restored.interval, 2);
    expect(restored.daysOfWeek, <int>[1, 3, 5]);
    expect(restored.onlyWorkingDays, isTrue);
    expect(restored.until, until);
  });

  test('defaults to none frequency when json is empty object', () {
    final RecurrenceRule rule =
        RecurrenceRule.fromJson(<String, dynamic>{});

    expect(rule.frequency, RecurrenceFrequency.none);
    expect(rule.interval, 1);
    expect(rule.onlyWorkingDays, isFalse);
  });
}
