import 'package:flutter/material.dart';

/// Maps contextual calendar ids to Material 3 [ColorScheme] accents (MVP).
class CalendarContextColors {
  CalendarContextColors._();

  static Color accentFor(
    BuildContext context, {
    required String calendarId,
    int? fallbackColorValue,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String key = calendarId.trim().toLowerCase();

    if (key == 'work' || key.contains('work') || key.contains('раб')) {
      return colors.primary;
    }
    if (key == 'personal' ||
        key.contains('personal') ||
        key.contains('личн')) {
      return colors.tertiary;
    }
    if (key == 'group' || key.contains('group') || key.contains('групп')) {
      return colors.secondary;
    }

    if (fallbackColorValue != null) {
      return Color(_normalizeArgb(fallbackColorValue));
    }
    return colors.primary;
  }

  /// M3-style badge colors for a task context calendar chip.
  static ({Color background, Color foreground}) badgeColorsFor(
    BuildContext context, {
    required String calendarId,
    int? fallbackColorValue,
  }) {
    final Color accent = accentFor(
      context,
      calendarId: calendarId,
      fallbackColorValue: fallbackColorValue,
    );
    return (
      background: accent.withValues(alpha: 0.22),
      foreground: accent,
    );
  }

  static int _normalizeArgb(int value) {
    if (value > 0xFFFFFF) {
      return value;
    }
    return 0xFF000000 | value;
  }
}
