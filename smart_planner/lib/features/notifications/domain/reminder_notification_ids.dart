/// Stable notification ids for scheduled task/event reminders.
abstract final class ReminderNotificationIds {
  ReminderNotificationIds._();

  static const int _taskBase = 1000000;
  static const int _eventBase = 2000000;

  static int forTask(int taskId) => _taskBase + taskId;

  static int forEvent(int eventId) => _eventBase + eventId;
}
