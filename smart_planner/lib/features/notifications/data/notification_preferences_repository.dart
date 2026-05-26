import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for notification features (foreground day-status bar, etc.).
class NotificationPreferencesRepository {
  NotificationPreferencesRepository({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  static const String _dayStatusBarEnabledKey = 'day_status_bar_enabled';

  final Future<SharedPreferences> _preferencesFuture;

  Future<bool> isDayStatusBarEnabled() async {
    final SharedPreferences prefs = await _preferencesFuture;
    return prefs.getBool(_dayStatusBarEnabledKey) ?? false;
  }

  Future<void> setDayStatusBarEnabled(bool enabled) async {
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setBool(_dayStatusBarEnabledKey, enabled);
  }
}
