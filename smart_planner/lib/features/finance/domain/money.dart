/// ISO 4217 minor-unit scale for common currencies (MVP subset).
const Map<String, int> currencyMinorUnitScale = <String, int>{
  'USD': 2,
  'EUR': 2,
  'GBP': 2,
  'RUB': 2,
  'JPY': 0,
  'KZT': 2,
  'UAH': 2,
  'TRY': 2,
  'CNY': 2,
  'INR': 2,
};

/// Default scale when [currencyCode] is unknown.
const int defaultMinorUnitScale = 2;

int minorUnitScaleFor(String currencyCode) {
  return currencyMinorUnitScale[currencyCode.toUpperCase()] ??
      defaultMinorUnitScale;
}

/// Converts a decimal amount to integer minor units for [currencyCode].
int amountToMinor(double amount, String currencyCode) {
  final int scale = minorUnitScaleFor(currencyCode);
  final double factor = _pow10(scale);
  return (amount * factor).round();
}

/// Converts [amountMinor] to a decimal major-unit value.
double minorToAmount(int amountMinor, String currencyCode) {
  final int scale = minorUnitScaleFor(currencyCode);
  final double factor = _pow10(scale);
  return amountMinor / factor;
}

double _pow10(int exponent) {
  double value = 1;
  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}

/// User-facing amount label (no FX conversion).
String formatMoneyMinor(int amountMinor, String currencyCode) {
  final String code = currencyCode.toUpperCase();
  final int scale = minorUnitScaleFor(code);
  final double amount = minorToAmount(amountMinor, code);
  return '$code ${amount.toStringAsFixed(scale)}';
}

/// Signed prefix for list rows: expense negative, income positive.
String formatSignedMoneyMinor(
  int amountMinor,
  String currencyCode, {
  required bool isExpense,
}) {
  final String base = formatMoneyMinor(amountMinor, currencyCode);
  if (isExpense) {
    return '−$base';
  }
  return '+$base';
}
