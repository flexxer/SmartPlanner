import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Domain contract for local calendar events (implemented by [LocalCalendarEventRepository]).
abstract class CalendarEventStore {
  Future<List<CalendarEvent>> getAll();

  Future<CalendarEvent?> getById(Id id);

  Future<CalendarEvent?> findByDeviceEventId(String deviceEventId);

  Future<Id> saveLocalEvent(CalendarEvent event);

  Future<void> upsertDeviceEvents(List<CalendarEvent> fromDevice);

  /// Removes device rows in [window] that were not returned by the latest fetch.
  ///
  /// Call only after a **successful** device read. Skips local-only and recurring rows.
  Future<int> purgeStaleDeviceEvents({
    required List<CalendarEvent> fetchedInWindow,
    required DateTime windowStart,
    required DateTime windowEndExclusive,
    required Set<String> syncedCalendarIds,
  });

  Future<void> linkTask({
    required Id eventId,
    required Id taskId,
  });

  Future<void> unlinkTask(Id taskId);

  Future<bool> deleteLocalEvent(Id eventId);

  Future<List<Task>> getLinkedTasks(CalendarEvent event);
}
