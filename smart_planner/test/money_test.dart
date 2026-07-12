import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/finance/domain/money.dart';

void main() {
  group('money', () {
    test('amountToMinor and minorToAmount round-trip for USD', () {
      expect(amountToMinor(12.34, 'USD'), 1234);
      expect(minorToAmount(1234, 'USD'), 12.34);
    });

    test('amountToMinor uses zero decimals for JPY', () {
      expect(amountToMinor(1500, 'JPY'), 1500);
      expect(minorUnitScaleFor('JPY'), 0);
    });

    test('formatSignedMoneyMinor prefixes expense and income', () {
      expect(
        formatSignedMoneyMinor(1050, 'USD', isExpense: true),
        '−USD 10.50',
      );
      expect(
        formatSignedMoneyMinor(1050, 'USD', isExpense: false),
        '+USD 10.50',
      );
    });
  });
}
