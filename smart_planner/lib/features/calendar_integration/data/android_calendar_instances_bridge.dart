import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Minimal Android [CalendarContract.Instances] read (no attendees).
abstract final class AndroidCalendarInstancesBridge {
  AndroidCalendarInstancesBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.aliakseipcholkin.smart_planner/calendar_instances',
  );

  static bool get isSupported => Platform.isAndroid;

  static Future<List<AndroidCalendarInstanceRow>> retrieveEvents({
    required List<String> calendarIds,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupported || calendarIds.isEmpty) {
      return const <AndroidCalendarInstanceRow>[];
    }

    final Object? raw = await _channel.invokeMethod<Object>(
      'retrieveEventsInRange',
      <String, Object>{
        'calendarIds': calendarIds,
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      },
    );
    return _parseJsonRows(raw);
  }

  static List<AndroidCalendarInstanceRow> _parseJsonRows(Object? raw) {
    if (raw is! String) {
      return const <AndroidCalendarInstanceRow>[];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => AndroidCalendarInstanceRow.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }
}

class AndroidCalendarInstanceRow {
  const AndroidCalendarInstanceRow({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.startMs,
    required this.endMs,
    required this.allDay,
  });

  factory AndroidCalendarInstanceRow.fromJson(Map<String, dynamic> json) {
    return AndroidCalendarInstanceRow(
      eventId: json['eventId'] as String,
      calendarId: json['calendarId'] as String,
      title: json['title'] as String? ?? '',
      startMs: (json['startMs'] as num).toInt(),
      endMs: (json['endMs'] as num).toInt(),
      allDay: json['allDay'] as bool? ?? false,
    );
  }

  final String eventId;
  final String calendarId;
  final String title;
  final int startMs;
  final int endMs;
  final bool allDay;
}
