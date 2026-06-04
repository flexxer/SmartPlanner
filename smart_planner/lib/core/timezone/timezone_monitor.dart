import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Detects device timezone changes and updates [tz.local].
class TimezoneMonitor {
  TimezoneMonitor._();

  static const String lastKnownTimezoneKey = 'last_known_timezone';

  /// Returns `true` when the timezone changed since the last persisted value.
  static Future<bool> applyIfChanged() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? previousTimeZone = prefs.getString(lastKnownTimezoneKey);

    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      await prefs.setString(lastKnownTimezoneKey, timeZoneName);
      return previousTimeZone != null && previousTimeZone != timeZoneName;
    } on Object {
      tz.setLocalLocation(tz.UTC);
      await prefs.setString(lastKnownTimezoneKey, 'UTC');
      return previousTimeZone != null && previousTimeZone != 'UTC';
    }
  }
}
