/// Android notification channel ids and action labels (non-localized keys).
abstract class NotificationChannels {
  static const String meetings = 'meetings_reminders';
  static const String taskDigest = 'task_digest';
  static const String overdueTasks = 'overdue_tasks';

  /// Ongoing foreground day-status bar (low importance, no sound).
  static const String dayStatus = 'day_status_bar';
}
