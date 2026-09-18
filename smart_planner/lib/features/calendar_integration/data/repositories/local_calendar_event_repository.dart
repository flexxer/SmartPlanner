import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/models/calendar_event_model.dart';
import 'package:smart_planner/features/calendar_integration/domain/device_calendar_stale_purge.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';
import 'package:smart_planner/features/calendar_integration/domain/repositories/calendar_event_store.dart';
import 'package:smart_planner/features/todo_list/data/models/task_model.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Isar persistence for local [CalendarEvent] records and task↔event links.
/// Maps between the pure domain entities and the [CalendarEventModel] /
/// [TaskModel] persistence rows and reports failures as [Result].
class LocalCalendarEventRepository implements CalendarEventStore {
  LocalCalendarEventRepository({this.isar});

  final Isar? isar;

  Isar get _db => isar ?? IsarDatabase.instance;

  @override
  Future<Result<List<CalendarEvent>>> getAll() async {
    try {
      final List<CalendarEventModel> list =
          await _db.calendarEventModels.where().sortByStart().findAll();
      return Success(
        list.map((CalendarEventModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load events: $error', stackTrace));
    }
  }

  @override
  Future<Result<CalendarEvent?>> getById(int id) async {
    try {
      final CalendarEventModel? model = await _db.calendarEventModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load event $id: $error', stackTrace));
    }
  }

  @override
  Future<Result<CalendarEvent?>> findByDeviceEventId(String deviceEventId) async {
    try {
      final CalendarEventModel? model = await _db.calendarEventModels
          .filter()
          .deviceEventIdEqualTo(deviceEventId)
          .findFirst();
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to find event: $error', stackTrace));
    }
  }

  /// Saves a user-created or edited local event (not synced to device calendar).
  @override
  Future<Result<CalendarEvent>> saveLocalEvent(CalendarEvent event) async {
    try {
      event.markUpdated();
      final CalendarEventModel model = CalendarEventModel.fromDomain(event);
      final int id = await _db.writeTxn(() => _db.calendarEventModels.put(model));
      event.id = id;
      return Success(event);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to save event: $error', stackTrace));
    }
  }

  /// Restores a deleted row with the same [CalendarEvent.id] (undo delete).
  Future<int> restoreEvent(CalendarEvent event) {
    event.markUpdated();
    final CalendarEventModel model = CalendarEventModel.fromDomain(event);
    return _db.writeTxn(() => _db.calendarEventModels.put(model));
  }

  /// Persists device-calendar rows without dropping local link/recurrence metadata.
  @override
  Future<Result<bool>> upsertDeviceEvents(List<CalendarEvent> fromDevice) async {
    if (fromDevice.isEmpty) {
      return const Success(true);
    }
    try {
      await _db.writeTxn(() async {
        for (final CalendarEvent incoming in fromDevice) {
          CalendarEventModel? existing = await _db.calendarEventModels
              .filter()
              .deviceEventIdEqualTo(incoming.deviceEventId)
              .findFirst();

          existing ??= await _findReconcilableLocalDuplicate(incoming);

          if (existing != null) {
            if (existing.source == EventSource.local ||
                existing.deviceEventId.startsWith('local_')) {
              existing.deviceEventId = incoming.deviceEventId;
            }
            existing
              ..title = incoming.title
              ..start = incoming.start
              ..end = incoming.end
              ..calendarId = incoming.calendarId
              ..colorValue = incoming.colorValue
              ..source = EventSource.device;
            if (incoming.googleEventId != null) {
              existing.googleEventId = incoming.googleEventId;
            }
            if (incoming.recurrenceRuleJson != null) {
              existing.recurrenceRuleJson = incoming.recurrenceRuleJson;
            }
            if (incoming.reminderMinutesBefore != null) {
              existing.reminderMinutesBefore = incoming.reminderMinutesBefore;
            }
            if (incoming.linkedTaskIds.isNotEmpty) {
              existing.linkedTaskIds = List<int>.from(incoming.linkedTaskIds);
            }
            existing.updatedAt = DateTime.now();
            await _db.calendarEventModels.put(existing);
          } else {
            incoming.source = EventSource.device;
            await _db.calendarEventModels.put(
              CalendarEventModel.fromDomain(incoming),
            );
          }
        }
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to upsert events: $error', stackTrace));
    }
  }

  /// Removes device rows in the sync window missing from [fetchedInWindow].
  @override
  Future<Result<int>> purgeStaleDeviceEvents({
    required List<CalendarEvent> fetchedInWindow,
    required DateTime windowStart,
    required DateTime windowEndExclusive,
    required Set<String> syncedCalendarIds,
  }) async {
    if (syncedCalendarIds.isEmpty) {
      return const Success(0);
    }
    try {
      final List<CalendarEvent> allStored =
          (await getAll()).getOrElse((_) => <CalendarEvent>[]);
      final List<CalendarEvent> stale = DeviceCalendarStalePurge.rowsToRemove(
        allStored: allStored,
        fetchedInWindow: fetchedInWindow,
        windowStart: windowStart,
        windowEndExclusive: windowEndExclusive,
        syncedCalendarIds: syncedCalendarIds,
      );

      var removed = 0;
      for (final CalendarEvent event in stale) {
        if ((await deleteLocalEvent(event.id)).getOrElse((_) => false)) {
          removed++;
        }
      }
      return Success(removed);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to purge events: $error', stackTrace));
    }
  }

  /// Matches app-created `local_*` rows to imported device events (same title/day).
  Future<CalendarEventModel?> _findReconcilableLocalDuplicate(
    CalendarEvent incoming,
  ) async {
    final List<CalendarEventModel> localRows = await _db.calendarEventModels
        .filter()
        .deviceEventIdStartsWith('local_')
        .findAll();
    final String titleKey = incoming.title.trim().toLowerCase();
    for (final CalendarEventModel local in localRows) {
      if (local.title.trim().toLowerCase() != titleKey) {
        continue;
      }
      if (!AppDateUtils.isSameCalendarDay(local.start, incoming.start)) {
        continue;
      }
      return local;
    }
    return null;
  }

  @override
  Future<Result<bool>> linkTask({
    required int eventId,
    required int taskId,
  }) async {
    try {
      await _db.writeTxn(() async {
        final CalendarEventModel? event = await _db.calendarEventModels.get(eventId);
        final TaskModel? task = await _db.taskModels.get(taskId);
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
        event.updatedAt = DateTime.now();

        await _db.taskModels.put(task);
        await _db.calendarEventModels.put(event);
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to link task: $error', stackTrace));
    }
  }

  @override
  Future<Result<bool>> unlinkTask(int taskId) async {
    try {
      await _db.writeTxn(() async {
        final TaskModel? task = await _db.taskModels.get(taskId);
        if (task == null) {
          return;
        }
        await _unlinkTaskInTxn(task);
        await _db.taskModels.put(task);
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to unlink task: $error', stackTrace));
    }
  }

  Future<void> _unlinkTaskInTxn(TaskModel task) async {
    final int? eventId = task.linkedEventId;
    if (eventId == null) {
      return;
    }

    final CalendarEventModel? event = await _db.calendarEventModels.get(eventId);
    task.linkedEventId = null;

    if (event != null) {
      event.linkedTaskIds =
          event.linkedTaskIds.where((int id) => id != task.id).toList();
      event.updatedAt = DateTime.now();
      await _db.calendarEventModels.put(event);
    }
  }

  /// Deletes a local event and unlinks any associated tasks.
  @override
  Future<Result<bool>> deleteLocalEvent(int eventId) async {
    try {
      final bool deleted = await _db.writeTxn(() async {
        final CalendarEventModel? event = await _db.calendarEventModels.get(eventId);
        if (event == null) {
          return false;
        }

        for (final int taskId in List<int>.from(event.linkedTaskIds)) {
          final TaskModel? task = await _db.taskModels.get(taskId);
          if (task != null) {
            await _unlinkTaskInTxn(task);
            await _db.taskModels.put(task);
          }
        }

        return _db.calendarEventModels.delete(eventId);
      });
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to delete event: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<Task>>> getLinkedTasks(CalendarEvent event) async {
    try {
      if (event.linkedTaskIds.isEmpty) {
        return const Success(<Task>[]);
      }

      final List<Task> tasks = <Task>[];
      for (final int taskId in event.linkedTaskIds) {
        final TaskModel? model = await _db.taskModels.get(taskId);
        if (model != null) {
          tasks.add(model.toDomain());
        }
      }
      return Success(tasks);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load linked tasks: $error', stackTrace));
    }
  }
}
