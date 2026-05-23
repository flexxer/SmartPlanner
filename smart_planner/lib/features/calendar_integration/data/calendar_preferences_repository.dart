import 'package:shared_preferences/shared_preferences.dart';

/// Сохранённые ID календарей устройства для отображения на дашборде.
class CalendarPreferencesRepository {
  CalendarPreferencesRepository({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  static const String _selectedIdsKey = 'selected_calendar_ids';

  final Future<SharedPreferences> _preferencesFuture;

  Future<List<String>?> getSelectedCalendarIds() async {
    final SharedPreferences prefs = await _preferencesFuture;
    return prefs.getStringList(_selectedIdsKey);
  }

  Future<void> saveSelectedCalendarIds(List<String> ids) async {
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setStringList(_selectedIdsKey, ids);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.remove(_selectedIdsKey);
  }
}
