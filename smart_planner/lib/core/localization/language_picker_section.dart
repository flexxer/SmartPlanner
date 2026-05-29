import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/app_locales.dart';
import 'package:smart_planner/core/localization/locale_preferences_repository.dart';

/// Language selector for the settings page (instant UI update).
class LanguagePickerSection extends StatefulWidget {
  const LanguagePickerSection({super.key});

  @override
  State<LanguagePickerSection> createState() => _LanguagePickerSectionState();
}

class _LanguagePickerSectionState extends State<LanguagePickerSection> {
  static const List<String> _pickerCodes = <String>[
    AppLocales.systemLanguageCode,
    'en',
    'ru',
    'es',
  ];

  String _selectedCode = AppLocales.systemLanguageCode;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCode();
  }

  Future<void> _loadSavedCode() async {
    final LocalePreferencesRepository prefs =
        context.read<LocalePreferencesRepository>();
    final Locale? saved = await prefs.getSavedLocale();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCode = AppLocales.languageCodeForPicker(saved);
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox.shrink();
    }

    final LocalePreferencesRepository prefs =
        context.read<LocalePreferencesRepository>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DropdownButtonFormField<String>(
            value: _pickerCodes.contains(_selectedCode)
                ? _selectedCode
                : AppLocales.systemLanguageCode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: _pickerCodes
                .map(
                  (String code) => DropdownMenuItem<String>(
                    value: code,
                    child: Text(AppLocales.pickerLabelKey(code).tr()),
                  ),
                )
                .toList(),
            onChanged: (String? code) async {
              if (code == null) {
                return;
              }
              final Locale? locale = AppLocales.localeFromLanguageCode(code);
              await prefs.saveLocale(locale);
              if (!context.mounted) {
                return;
              }
              setState(() => _selectedCode = code);
              if (locale == null) {
                await context.resetLocale();
              } else {
                await context.setLocale(locale);
              }
            },
          ),
    );
  }
}
