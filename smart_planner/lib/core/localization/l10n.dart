import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/app_locales.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Localization helpers usable with or without [BuildContext].
abstract final class L10n {
  static String tr(String key, {Map<String, String>? namedArgs}) {
    if (namedArgs != null && namedArgs.isNotEmpty) {
      return key.tr(namedArgs: namedArgs);
    }
    return key.tr();
  }

  static String overdueDays(int days) {
    return 'overdue_days'.plural(
      days,
      namedArgs: <String, String>{'days': '$days'},
    );
  }

  static String priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => tr('priority_low'),
      TaskPriority.medium => tr('priority_medium'),
      TaskPriority.high => tr('priority_high'),
      TaskPriority.urgent => tr('priority_urgent'),
    };
  }

  static String priorityLabelWithSuffix(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => tr('priority_low_full'),
      TaskPriority.medium => tr('priority_medium_full'),
      TaskPriority.high => tr('priority_high_full'),
      TaskPriority.urgent => tr('priority_urgent_full'),
    };
  }

  static String recurrenceLabel(String frequencyKey) {
    return tr('recurrence_$frequencyKey');
  }

  /// [DateFormat] using the active easy_localization locale.
  static DateFormat dateFormat(String pattern, {BuildContext? context}) {
    final String code = context != null
        ? context.locale.languageCode
        : _languageCodeFromIntl();
    return DateFormat(pattern, code);
  }

  static Locale activeLocale({BuildContext? context}) {
    if (context != null) {
      return context.locale;
    }
    final String code = _languageCodeFromIntl();
    return Locale(code);
  }

  static String _languageCodeFromIntl() {
    final String raw = Intl.getCurrentLocale();
    if (raw.isEmpty) {
      return AppLocales.fallback.languageCode;
    }
    return raw.split('_').first;
  }
}
