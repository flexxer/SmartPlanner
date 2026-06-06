import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG contrast helpers for badges, chips, and accent labels.
abstract final class AppColorUtils {
  static const double _minContrastRatio = 4.5;

  /// Tinted chip/badge colors from an accent (calendar color, status, etc.).
  static ({Color background, Color foreground}) chipFromAccent(
    Color accent,
    ColorScheme scheme,
  ) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color background = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.34 : 0.18),
      isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
    );
    final Color foreground = accentLabel(
      accent,
      scheme,
      onBackground: background,
    );
    return (background: background, foreground: foreground);
  }

  /// Readable accent-colored text on a neutral surface (event time, labels).
  static Color accentLabel(
    Color accent,
    ColorScheme scheme, {
    Color? onBackground,
    bool muted = false,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final double mix = muted
        ? (isDark ? 0.5 : 0.62)
        : (isDark ? 0.28 : 0.74);
    final Color base = isDark ? Colors.white : Colors.black;
    final Color candidate = Color.alphaBlend(
      accent.withValues(alpha: 1 - mix),
      base,
    );

    if (onBackground != null &&
        _contrastRatio(candidate, onBackground) < _minContrastRatio) {
      return isDark ? scheme.onSurface : const Color(0xFF1A1C22);
    }
    return candidate;
  }

  static double _contrastRatio(Color foreground, Color background) {
    final double l1 = _relativeLuminance(foreground);
    final double l2 = _relativeLuminance(background);
    final double lighter = math.max(l1, l2);
    final double darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color color) {
    double channel(double value) {
      final double normalized = value / 255;
      return normalized <= 0.03928
          ? normalized / 12.92
          : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r * 255) +
        0.7152 * channel(color.g * 255) +
        0.0722 * channel(color.b * 255);
  }
}
