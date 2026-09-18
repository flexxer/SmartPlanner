import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';

part 'calendar_event_model.g.dart';

/// Isar persistence model for [CalendarEvent].
@collection
class CalendarEventModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String deviceEventId;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  late DateTime start;

  late DateTime end;

  @Index()
  late String calendarId;

  int colorValue = 0xFF5C6BC0;

  String? googleEventId;

  @Enumerated(EnumType.ordinal)
  EventSource source = EventSource.local;

  DateTime? updatedAt;

  String? recurrenceRuleJson;

  List<int> linkedTaskIds = <int>[];

  int? reminderMinutesBefore;

  String? syncedDeviceEventIdsJson;

  CalendarEvent toDomain() => CalendarEvent(id: id)
    ..deviceEventId = deviceEventId
    ..title = title
    ..start = start
    ..end = end
    ..calendarId = calendarId
    ..colorValue = colorValue
    ..googleEventId = googleEventId
    ..source = source
    ..updatedAt = updatedAt
    ..recurrenceRuleJson = recurrenceRuleJson
    ..linkedTaskIds = List<int>.from(linkedTaskIds)
    ..reminderMinutesBefore = reminderMinutesBefore
    ..syncedDeviceEventIdsJson = syncedDeviceEventIdsJson;

  static CalendarEventModel fromDomain(CalendarEvent event) {
    final CalendarEventModel model = CalendarEventModel()
      ..deviceEventId = event.deviceEventId
      ..title = event.title
      ..start = event.start
      ..end = event.end
      ..calendarId = event.calendarId
      ..colorValue = event.colorValue
      ..googleEventId = event.googleEventId
      ..source = event.source
      ..updatedAt = event.updatedAt
      ..recurrenceRuleJson = event.recurrenceRuleJson
      ..linkedTaskIds = List<int>.from(event.linkedTaskIds)
      ..reminderMinutesBefore = event.reminderMinutesBefore
      ..syncedDeviceEventIdsJson = event.syncedDeviceEventIdsJson;
    if (event.id > 0) {
      model.id = event.id;
    }
    return model;
  }
}
