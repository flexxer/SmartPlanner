import 'package:flutter/material.dart';

/// Global Material 3 theme for DayLinx.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF5C6BC0);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// Background for grouped blocks (settings sections, dashboard panels).
  static Color groupedSectionFill(ColorScheme colors) => colors.surface;

  static Color groupedSectionBorder(ColorScheme colors) => colors.outlineVariant;

  static BoxDecoration groupedSectionDecoration(ColorScheme colors) {
    return BoxDecoration(
      color: groupedSectionFill(colors),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: groupedSectionBorder(colors)),
    );
  }

  static BoxDecoration insetCardDecoration(
    ColorScheme colors, {
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: groupedSectionBorder(colors)),
    );
  }

  static RoundedRectangleBorder insetCardShape(
    ColorScheme colors, {
    double borderRadius = 12,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: groupedSectionBorder(colors)),
    );
  }

  static ChipThemeData infoChipTheme(ColorScheme colors) {
    return ChipThemeData(
      backgroundColor: colors.primaryContainer,
      labelStyle: TextStyle(color: colors.onPrimaryContainer),
      side: BorderSide(color: colors.primary.withValues(alpha: 0.24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = brightness == Brightness.light
        ? _lightColorScheme()
        : _darkColorScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
      ),
    );
  }

  static ColorScheme _lightColorScheme() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return base.copyWith(
      surface: const Color(0xFFFAFAFC),
      onSurface: const Color(0xFF1A1C22),
      onSurfaceVariant: const Color(0xFF454854),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF3F4F8),
      surfaceContainer: const Color(0xFFEDEEF3),
      surfaceContainerHigh: const Color(0xFFE6E8EE),
      surfaceContainerHighest: const Color(0xFFDFE2E9),
      primary: const Color(0xFF4A56A8),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD8DCF2),
      onPrimaryContainer: const Color(0xFF141B4D),
      secondary: const Color(0xFF4A6280),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD3E0F2),
      onSecondaryContainer: const Color(0xFF102A48),
      tertiary: const Color(0xFF6B4F82),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE9DDF2),
      onTertiaryContainer: const Color(0xFF331845),
      errorContainer: const Color(0xFFF9DEDC),
      onErrorContainer: const Color(0xFF601410),
      outline: const Color(0xFF747986),
      outlineVariant: const Color(0xFFC5C8D1),
    );
  }

  static ColorScheme _darkColorScheme() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      surface: const Color(0xFF121318),
      onSurface: const Color(0xFFE4E2E8),
      onSurfaceVariant: const Color(0xFFC4C6D0),
      surfaceContainerLowest: const Color(0xFF0C0D11),
      surfaceContainerLow: const Color(0xFF1C1D24),
      surfaceContainer: const Color(0xFF212229),
      surfaceContainerHigh: const Color(0xFF2B2C33),
      surfaceContainerHighest: const Color(0xFF36373F),
      primary: const Color(0xFFB8C3FF),
      onPrimary: const Color(0xFF1A2578),
      primaryContainer: const Color(0xFF3A4580),
      onPrimaryContainer: const Color(0xFFDEE1FF),
      secondary: const Color(0xFFB8CCE8),
      onSecondary: const Color(0xFF20344C),
      secondaryContainer: const Color(0xFF334B6B),
      onSecondaryContainer: const Color(0xFFD3E4FF),
      tertiary: const Color(0xFFD9BEE8),
      onTertiary: const Color(0xFF402850),
      tertiaryContainer: const Color(0xFF4D3F5C),
      onTertiaryContainer: const Color(0xFFEAD9F7),
      errorContainer: const Color(0xFF601410),
      onErrorContainer: const Color(0xFFF9DEDC),
      outline: const Color(0xFF8E9099),
      outlineVariant: const Color(0xFF44464F),
    );
  }
}
