import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's default ISO 4217 currency for new payments.
class CurrencyPreferencesRepository {
  static const String keyDefaultCurrencyCode = 'app_default_currency_code';
  static const String defaultCurrencyCode = 'USD';

  static const List<String> supportedCurrencyCodes = <String>[
    'USD',
    'EUR',
    'GBP',
    'RUB',
    'JPY',
    'KZT',
    'UAH',
    'TRY',
    'CNY',
    'INR',
  ];

  Future<String> getDefaultCurrencyCode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(keyDefaultCurrencyCode);
    if (code == null || code.isEmpty) {
      return defaultCurrencyCode;
    }
    return code.toUpperCase();
  }

  Future<void> setDefaultCurrencyCode(String currencyCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      keyDefaultCurrencyCode,
      currencyCode.toUpperCase(),
    );
  }
}
