import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Isar persistence for local [CalendarEvent] records and task↔event links.
class LocalCalendarEventRepository {
  LocalCalendarEventRepository({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<CalendarEvent>> getAll() =>
      _db.calendarEvents.where().sortByStart().findAll();

  Future<CalendarEvent?> getById(Id id) => _db.calendarEvents.get(id);

  Future<CalendarEvent?> findByDeviceEventId(String deviceEventId) =>
      _db.calendarEvents
          .filter()
          .deviceEventIdEqualTo(deviceEventId)
          .findFirst();

  /// Saves a user-created or edited local event (not synced to device calendar).
  Future<Id> saveLocalEvent(CalendarEvent event) =>
      _db.writeTxn(() => _db.calendarEvents.put(event));

  /// Persists device-calendar rows without dropping local link/recurrence metadata.
  Future<void> upsertDeviceEvents(List<CalendarEvent> fromDevice) async {
    if (fromDevice.isEmpty) {
      return;
    }

    await _db.writeTxn(() async {
      for (final CalendarEvent incoming in fromDevice) {
        final CalendarEvent? existing =
            await _db.calendarEvents
                .filter()
                .deviceEventIdEqualTo(incoming.deviceEventId)
                .findFirst();

        if (existing != null) {
          existing
            ..title = incoming.title
            ..start = incoming.start
            ..end = incoming.end
            ..calendarId = incoming.calendarId
            ..colorValue = incoming.colorValue;
          await _db.calendarEvents.put(existing);
        } else {
          await _db.calendarEvents.put(incoming);
        }
      }
    });
  }

  Future<void> linkTask({
    required Id eventId,
    required Id taskId,
  }) async {
    await _db.writeTxn(() async {
      final CalendarEvent? event = await _db.calendarEvents.get(eventId);
      final Task? task = await _db.tasks.get(taskId);
      if (event == null || task == null) {
        return;
      }

      await _unlinkTaskInTxn(task);

      task
        ..linkedEventId = eventId
        ..calendarId = event.calendarId;
      if (!event.linkedTaskIds.contains(taskId)) {
        event.linkedTaskIds = <int>[...event.linkedTaskIds, taskId];
      }

      await _db.tasks.put(task);
      await _db.calendarEvents.put(event);
    });
  }

  Future<void> unlinkTask(Id taskId) async {
    await _db.writeTxn(() async {
      final Task? task = await _db.tasks.get(taskId);
      if (task == null) {
        return;
      }
      await _unlinkTaskInTxn(task);
      await _db.tasks.put(task);
    });
  }

  Future<void> _unlinkTaskInTxn(Task task) async {
    final Id? eventId = task.linkedEventId;
    if (eventId == null) {
      return;
    }

    final CalendarEvent? event = await _db.calendarEvents.get(eventId);
    task.linkedEventId = null;

    if (event != null) {
      event.linkedTaskIds =
          event.linkedTaskIds.where((int id) => id != task.id).toList();
      await _db.calendarEvents.put(event);
    }
  }

  /// Deletes a local event and unlinks any associated tasks.
  Future<bool> deleteLocalEvent(Id eventId) async {
    return _db.writeTxn(() async {
      final CalendarEvent? event = await _db.calendarEvents.get(eventId);
      if (event == null) {
        return false;
      }

      for (final int taskId in List<int>.from(event.linkedTaskIds)) {
        final Task? task = await _db.tasks.get(taskId);
        if (task != null) {
          await _unlinkTaskInTxn(task);
          await _db.tasks.put(task);
        }
      }

      return _db.calendarEvents.delete(eventId);
    });
  }

  Future<List<Task>> getLinkedTasks(CalendarEvent event) async {
    if (event.linkedTaskIds.isEmpty) {
      return const <Task>[];
    }

    final List<Task> tasks = <Task>[];
    for (final int taskId in event.linkedTaskIds) {
      final Task? task = await _db.tasks.get(taskId);
      if (task != null) {
        tasks.add(task);
      }
    }
    return tasks;
  }
}
