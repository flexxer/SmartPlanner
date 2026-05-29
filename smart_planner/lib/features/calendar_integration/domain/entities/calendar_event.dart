import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';

part 'calendar_event.g.dart';

/// Local calendar event (Isar) with links to tasks and recurrence metadata.
@collection
class CalendarEvent {
  Id id = Isar.autoIncrement;

  /// Stable identifier from the device calendar plugin ([device_calendar]).
  @Index()
  late String deviceEventId;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  late DateTime start;
  late DateTime end;

  /// Context calendar id (Work, Personal, group calendar, etc.).
  @Index()
  late String calendarId;

  int colorValue = 0xFF5C6BC0;

  /// Future Google Calendar sync id.
  String? googleEventId;

  /// JSON payload from [RecurrenceRule.toJsonString].
  String? recurrenceRuleJson;

  /// Local [Task.id] values linked to this event.
  List<int> linkedTaskIds = <int>[];

  /// Minutes before [start]; `null` = no reminder.
  int? reminderMinutesBefore;

  CalendarEvent();

  /// User-created event stored only in Isar (MVP local meetings).
  factory CalendarEvent.createLocal({
    required String title,
    required DateTime start,
    required DateTime end,
    required String calendarId,
    int colorValue = 0xFF5C6BC0,
    RecurrenceRule? recurrenceRule,
  }) {
    final String deviceEventId =
        'local_${DateTime.now().microsecondsSinceEpoch}';
    return CalendarEvent.fromDevice(
      deviceEventId: deviceEventId,
      title: title,
      start: start,
      end: end,
      calendarId: calendarId,
      colorValue: colorValue,
      recurrenceRule: recurrenceRule,
    );
  }

  /// Maps a device-calendar row into a persistable [CalendarEvent].
  factory CalendarEvent.fromDevice({
    required String deviceEventId,
    required String title,
    required DateTime start,
    required DateTime end,
    required String calendarId,
    required int colorValue,
    String? googleEventId,
    RecurrenceRule? recurrenceRule,
    List<int>? linkedTaskIds,
  }) {
    final CalendarEvent event = CalendarEvent()
      ..deviceEventId = deviceEventId
      ..title = title
      ..start = start
      ..end = end
      ..calendarId = calendarId
      ..colorValue = colorValue
      ..googleEventId = googleEventId
      ..linkedTaskIds = linkedTaskIds ?? <int>[];

    if (recurrenceRule != null) {
      event.recurrenceRuleJson = recurrenceRule.toJsonString();
    }
    return event;
  }

  @ignore
  RecurrenceRule? get recurrenceRule {
    final String? json = recurrenceRuleJson;
    if (json == null || json.isEmpty) {
      return null;
    }
    return RecurrenceRule.fromJsonString(json);
  }

  @ignore
  set recurrenceRule(RecurrenceRule? rule) {
    recurrenceRuleJson = rule?.toJsonString();
  }
}
