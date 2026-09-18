import 'package:smart_planner/features/calendar_integration/domain/calendar_event_sync_mapping.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';

/// Local calendar event with links to tasks and recurrence metadata.
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `CalendarEventModel` in the data layer.
class CalendarEvent {
  CalendarEvent({this.id = 0});

  /// User-created event stored only locally (MVP local meetings).
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
      source: EventSource.local,
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
    EventSource source = EventSource.device,
  }) {
    final CalendarEvent event = CalendarEvent()
      ..deviceEventId = deviceEventId
      ..title = title
      ..start = start
      ..end = end
      ..calendarId = calendarId
      ..colorValue = colorValue
      ..googleEventId = googleEventId
      ..source = source
      ..linkedTaskIds = linkedTaskIds ?? <int>[];

    if (recurrenceRule != null) {
      event.recurrenceRuleJson = recurrenceRule.toJsonString();
    }
    event.markUpdated();
    return event;
  }

  /// Database id; `0` until persisted.
  int id;

  /// Stable identifier from the device calendar plugin.
  String deviceEventId = '';

  String title = '';

  DateTime start = DateTime.now();

  DateTime end = DateTime.now();

  /// Context calendar id (Work, Personal, group calendar, etc.).
  String calendarId = '';

  int colorValue = 0xFF5C6BC0;

  /// Future Google Calendar sync id.
  String? googleEventId;

  EventSource source = EventSource.local;

  /// Last mutation time for sync conflict resolution.
  DateTime? updatedAt;

  /// JSON payload from [RecurrenceRule.toJsonString].
  String? recurrenceRuleJson;

  /// Local [Task.id] values linked to this event.
  List<int> linkedTaskIds = <int>[];

  /// Minutes before [start]; `null` = no reminder.
  int? reminderMinutesBefore;

  /// JSON map of device calendar id → device event id (outbound sync targets).
  String? syncedDeviceEventIdsJson;

  /// Sets [updatedAt] to now. Call after in-memory field changes before persisting.
  void markUpdated() {
    updatedAt = DateTime.now();
  }

  /// True when the row exists only locally (`local_` id or [EventSource.local]).
  bool get isLocalOnly =>
      source == EventSource.local || deviceEventId.startsWith('local_');

  Map<String, String> get syncedDeviceEventIds =>
      CalendarEventSyncMapping.decode(syncedDeviceEventIdsJson);

  set syncedDeviceEventIds(Map<String, String> mapping) {
    syncedDeviceEventIdsJson = CalendarEventSyncMapping.encode(mapping);
  }

  List<String> get syncedCalendarIds =>
      CalendarEventSyncMapping.calendarIds(syncedDeviceEventIds);

  bool get isSyncedToDevice => syncedDeviceEventIds.isNotEmpty;

  RecurrenceRule? get recurrenceRule {
    final String? json = recurrenceRuleJson;
    if (json == null || json.isEmpty) {
      return null;
    }
    return RecurrenceRule.fromJsonString(json);
  }

  set recurrenceRule(RecurrenceRule? rule) {
    recurrenceRuleJson = rule?.toJsonString();
  }
}
