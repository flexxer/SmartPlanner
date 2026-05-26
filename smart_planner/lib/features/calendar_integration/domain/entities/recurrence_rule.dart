import 'dart:convert';

import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';

/// Typed recurrence specification for calendar events (stored as JSON in Isar).
class RecurrenceRule {
  const RecurrenceRule({
    this.frequency = RecurrenceFrequency.none,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.weekOfMonth,
    this.onlyWorkingDays = false,
    this.until,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  /// ISO weekday: 1 = Monday, 7 = Sunday.
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  /// 1 = first week of month, -1 = last week of month (convention for complex monthly rules).
  final int? weekOfMonth;
  final bool onlyWorkingDays;
  final DateTime? until;

  /// Serializes this rule to a JSON string for [CalendarEvent.recurrenceRuleJson].
  String toJsonString() => jsonEncode(toJson());

  /// Parses a JSON string produced by [toJsonString].
  factory RecurrenceRule.fromJsonString(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('RecurrenceRule JSON must be an object');
    }
    return RecurrenceRule.fromJson(decoded);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frequency': frequency.name,
      'interval': interval,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      if (weekOfMonth != null) 'weekOfMonth': weekOfMonth,
      'onlyWorkingDays': onlyWorkingDays,
      if (until != null) 'until': until!.toUtc().toIso8601String(),
    };
  }

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    final String? frequencyName = json['frequency'] as String?;
    final RecurrenceFrequency frequency = RecurrenceFrequency.values.firstWhere(
      (RecurrenceFrequency f) => f.name == frequencyName,
      orElse: () => RecurrenceFrequency.none,
    );

    return RecurrenceRule(
      frequency: frequency,
      interval: json['interval'] as int? ?? 1,
      daysOfWeek: _parseDaysOfWeek(json['daysOfWeek']),
      dayOfMonth: json['dayOfMonth'] as int?,
      weekOfMonth: json['weekOfMonth'] as int?,
      onlyWorkingDays: json['onlyWorkingDays'] as bool? ?? false,
      until: _parseUntil(json['until']),
    );
  }

  static List<int>? _parseDaysOfWeek(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! List<Object?>) {
      throw FormatException('daysOfWeek must be a list of integers');
    }
    return value.map((Object? e) => e as int).toList(growable: false);
  }

  static DateTime? _parseUntil(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('until must be an ISO-8601 string');
    }
    return DateTime.parse(value).toLocal();
  }
}
