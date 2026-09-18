import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Domain contract for local calendar events (implemented by [LocalCalendarEventRepository]).
abstract class CalendarEventStore {
  Future<Result<List<CalendarEvent>>> getAll();

  Future<Result<CalendarEvent?>> getById(int id);

  Future<Result<CalendarEvent?>> findByDeviceEventId(String deviceEventId);

  Future<Result<CalendarEvent>> saveLocalEvent(CalendarEvent event);

  Future<Result<bool>> upsertDeviceEvents(List<CalendarEvent> fromDevice);

  /// Removes device rows in [window] that were not returned by the latest fetch.
  ///
  /// Call only after a **successful** device read. Skips local-only and recurring rows.
  Future<Result<int>> purgeStaleDeviceEvents({
    required List<CalendarEvent> fetchedInWindow,
    required DateTime windowStart,
    required DateTime windowEndExclusive,
    required Set<String> syncedCalendarIds,
  });

  Future<Result<bool>> linkTask({
    required int eventId,
    required int taskId,
  });

  Future<Result<bool>> unlinkTask(int taskId);

  Future<Result<bool>> deleteLocalEvent(int eventId);

  Future<Result<List<Task>>> getLinkedTasks(CalendarEvent event);
}
