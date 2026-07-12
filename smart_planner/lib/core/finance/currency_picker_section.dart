import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/finance/currency_preferences_repository.dart';

/// Default currency dropdown on the settings page.
class CurrencyPickerSection extends StatefulWidget {
  const CurrencyPickerSection({super.key});

  @override
  State<CurrencyPickerSection> createState() => _CurrencyPickerSectionState();
}

class _CurrencyPickerSectionState extends State<CurrencyPickerSection> {
  String _selectedCode = CurrencyPreferencesRepository.defaultCurrencyCode;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCode();
  }

  Future<void> _loadSavedCode() async {
    final CurrencyPreferencesRepository prefs =
        context.read<CurrencyPreferencesRepository>();
    final String code = await prefs.getDefaultCurrencyCode();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCode = code;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox.shrink();
    }

    final CurrencyPreferencesRepository prefs =
        context.read<CurrencyPreferencesRepository>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DropdownButtonFormField<String>(
        value: CurrencyPreferencesRepository.supportedCurrencyCodes
                .contains(_selectedCode)
            ? _selectedCode
            : CurrencyPreferencesRepository.defaultCurrencyCode,
        decoration: InputDecoration(
          labelText: 'finance_default_currency'.tr(),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: CurrencyPreferencesRepository.supportedCurrencyCodes
            .map(
              (String code) => DropdownMenuItem<String>(
                value: code,
                child: Text(code),
              ),
            )
            .toList(),
        onChanged: (String? code) async {
          if (code == null) {
            return;
          }
          await prefs.setDefaultCurrencyCode(code);
          if (!mounted) {
            return;
          }
          setState(() => _selectedCode = code);
        },
      ),
    );
  }
}
