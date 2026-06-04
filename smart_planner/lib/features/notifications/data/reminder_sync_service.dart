import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Schedules or cancels OS reminders after entity changes (best-effort).
class ReminderSyncService {
  ReminderSyncService(this._scheduler);

  final ItemReminderScheduler _scheduler;

  Future<void> syncTask(Task task) async {
    try {
      await _scheduler.syncTask(task);
    } on Object {
      // Scheduling is best-effort; persistence already succeeded.
    }
  }

  Future<void> syncEvent(CalendarEvent event) async {
    try {
      await _scheduler.syncEvent(event);
    } on Object {
      // Scheduling is best-effort; persistence already succeeded.
    }
  }

  Future<void> cancelTask(int taskId) async {
    try {
      await _scheduler.cancelTask(taskId);
    } on Object {
      //
    }
  }

  Future<void> cancelEvent(int eventId) async {
    try {
      await _scheduler.cancelEvent(eventId);
    } on Object {
      //
    }
  }

  /// Re-registers reminders for device rows persisted via [upsertDeviceEvents].
  Future<void> syncDeviceEventsAfterUpsert({
    required LocalCalendarEventRepository localEvents,
    required List<CalendarEvent> fromDevice,
  }) async {
    for (final CalendarEvent incoming in fromDevice) {
      try {
        final CalendarEvent? stored = await localEvents.findByDeviceEventId(
          incoming.deviceEventId,
        );
        if (stored != null) {
          await _scheduler.syncEvent(stored);
        }
      } on Object {
        //
      }
    }
  }
}
