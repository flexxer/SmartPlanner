import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/theme/app_theme_mode.dart';
import 'package:smart_planner/core/theme/theme_preferences_repository.dart';

/// Theme selector for the settings page (instant UI update).
class ThemePickerSection extends StatefulWidget {
  const ThemePickerSection({super.key});

  @override
  State<ThemePickerSection> createState() => _ThemePickerSectionState();
}

class _ThemePickerSectionState extends State<ThemePickerSection> {
  String _selectedCode = AppThemeMode.systemCode;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCode();
  }

  Future<void> _loadSavedCode() async {
    final ThemePreferencesRepository prefs =
        context.read<ThemePreferencesRepository>();
    final ThemeMode saved = await prefs.getSavedThemeMode();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCode = AppThemeMode.codeForPicker(saved);
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox.shrink();
    }

    final ThemePreferencesRepository prefs =
        context.read<ThemePreferencesRepository>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DropdownButtonFormField<String>(
        value: AppThemeMode.pickerCodes.contains(_selectedCode)
            ? _selectedCode
            : AppThemeMode.systemCode,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: AppThemeMode.pickerCodes
            .map(
              (String code) => DropdownMenuItem<String>(
                value: code,
                child: Text(AppThemeMode.pickerLabelKey(code).tr()),
              ),
            )
            .toList(),
        onChanged: (String? code) async {
          if (code == null) {
            return;
          }
          final ThemeMode mode = AppThemeMode.themeModeFromCode(code);
          await prefs.setThemeMode(mode);
          if (!mounted) {
            return;
          }
          setState(() => _selectedCode = code);
        },
      ),
    );
  }
}
