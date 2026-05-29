import 'package:easy_localization/easy_localization.dart';

/// Localized labels for reminder offsets (shared by picker and detail views).
abstract final class ReminderLabels {
  ReminderLabels._();

  /// [minutes] `null` → “None”.
  static String labelForMinutes(int? minutes) {
    if (minutes == null) {
      return 'reminder_none'.tr();
    }
    return _labelForPositiveMinutes(minutes);
  }

  static String _labelForPositiveMinutes(int minutes) {
    if (minutes == 0) {
      return 'reminder_at_time'.tr();
    }
    if (minutes < 60) {
      return 'reminder_minutes_before'.tr(
        namedArgs: <String, String>{'count': '$minutes'},
      );
    }
    if (minutes == 60) {
      return 'reminder_one_hour_before'.tr();
    }
    if (minutes == 120) {
      return 'reminder_two_hours_before'.tr();
    }
    if (minutes == 1440) {
      return 'reminder_one_day_before'.tr();
    }
    return 'reminder_minutes_before'.tr(
      namedArgs: <String, String>{'count': '$minutes'},
    );
  }
}
