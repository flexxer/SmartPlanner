import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/features/notifications/domain/reminder_options.dart';

/// User preferences for notification features (foreground day-status bar, etc.).
class NotificationPreferencesRepository {
  NotificationPreferencesRepository({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  static const String _dayStatusBarEnabledKey = 'day_status_bar_enabled';
  static const String _dayStatusBarPinnedKey = 'day_status_bar_pinned';
  static const String _defaultReminderMinutesKey = 'default_reminder_minutes';
  static const String _defaultTaskReminderHourKey = 'default_task_reminder_hour';
  static const String _defaultTaskReminderMinuteKey =
      'default_task_reminder_minute';

  final Future<SharedPreferences> _preferencesFuture;

  Future<bool> isDayStatusBarEnabled() async {
    final SharedPreferences prefs = await _preferencesFuture;
    return prefs.getBool(_dayStatusBarEnabledKey) ?? false;
  }

  Future<void> setDayStatusBarEnabled(bool enabled) async {
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setBool(_dayStatusBarEnabledKey, enabled);
  }

  /// When true, uses a high-importance channel so the day-status notification sorts higher.
  Future<bool> isDayStatusBarPinned() async {
    final SharedPreferences prefs = await _preferencesFuture;
    return prefs.getBool(_dayStatusBarPinnedKey) ?? true;
  }

  Future<void> setDayStatusBarPinned(bool pinned) async {
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setBool(_dayStatusBarPinnedKey, pinned);
  }

  /// Default clock time when prefilling [Task.reminderAt] on the due day.
  Future<TimeOfDay> getDefaultTaskReminderTime() async {
    final SharedPreferences prefs = await _preferencesFuture;
    final int hour = prefs.getInt(_defaultTaskReminderHourKey) ?? 9;
    final int minute = prefs.getInt(_defaultTaskReminderMinuteKey) ?? 0;
    return TimeOfDay(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
  }

  Future<void> setDefaultTaskReminderTime(TimeOfDay time) async {
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setInt(_defaultTaskReminderHourKey, time.hour);
    await prefs.setInt(_defaultTaskReminderMinuteKey, time.minute);
  }

  /// Default offset for new calendar events (minutes before [CalendarEvent.start]).
  Future<int> getDefaultReminderMinutes() async {
    final SharedPreferences prefs = await _preferencesFuture;
    final int? stored = prefs.getInt(_defaultReminderMinutesKey);
    if (stored != null && ReminderOptions.selectableMinutes.contains(stored)) {
      return stored;
    }
    return ReminderOptions.defaultMinutes;
  }

  Future<void> setDefaultReminderMinutes(int minutes) async {
    if (!ReminderOptions.selectableMinutes.contains(minutes)) {
      return;
    }
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setInt(_defaultReminderMinutesKey, minutes);
  }
}
