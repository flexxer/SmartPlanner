import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_aggregates.dart';
import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

void main() {
  group('PaymentAggregates', () {
    test('totalsByCurrency groups income and expense per currency', () {
      final List<Payment> payments = <Payment>[
        Payment.create(
          title: 'Salary',
          amountMinor: 500_000,
          currencyCode: 'USD',
          direction: PaymentDirection.income,
          status: PaymentStatus.completed,
        ),
        Payment.create(
          title: 'Rent',
          amountMinor: 120_000,
          currencyCode: 'USD',
          direction: PaymentDirection.expense,
          status: PaymentStatus.completed,
        ),
        Payment.create(
          title: 'Freelance',
          amountMinor: 80_000,
          currencyCode: 'EUR',
          direction: PaymentDirection.income,
          status: PaymentStatus.planned,
        ),
        Payment.create(
          title: 'Cancelled',
          amountMinor: 10_000,
          currencyCode: 'USD',
          direction: PaymentDirection.expense,
          status: PaymentStatus.cancelled,
        ),
      ];

      final Map<String, CurrencyPaymentTotals> totals =
          PaymentAggregates.totalsByCurrency(payments);

      expect(totals['USD']!.incomeMinor, 500_000);
      expect(totals['USD']!.expenseMinor, 120_000);
      expect(totals['USD']!.balanceMinor, 380_000);
      expect(totals['EUR']!.incomeMinor, 80_000);
      expect(totals['EUR']!.expenseMinor, 0);
    });

    test('totalsByCurrency respects status filter', () {
      final Payment payment = Payment.create(
        title: 'Planned bill',
        amountMinor: 3_000,
        currencyCode: 'USD',
        direction: PaymentDirection.expense,
        status: PaymentStatus.planned,
      );

      final Map<String, CurrencyPaymentTotals> all =
          PaymentAggregates.totalsByCurrency(<Payment>[payment]);
      final Map<String, CurrencyPaymentTotals> completedOnly =
          PaymentAggregates.totalsByCurrency(
        <Payment>[payment],
        statusFilter: PaymentStatus.completed,
      );

      expect(all['USD']!.expenseMinor, 3_000);
      expect(completedOnly, isEmpty);
    });

    test('forMonth filters by occurredAt month', () {
      final Payment january = Payment.create(
        title: 'Jan',
        amountMinor: 100,
        currencyCode: 'USD',
        direction: PaymentDirection.income,
        occurredAt: DateTime(2026, 1, 15),
      );
      final Payment february = Payment.create(
        title: 'Feb',
        amountMinor: 200,
        currencyCode: 'USD',
        direction: PaymentDirection.income,
        occurredAt: DateTime(2026, 2, 1),
      );

      final List<Payment> janOnly = PaymentAggregates.forMonth(
        <Payment>[january, february],
        year: 2026,
        month: 1,
      );

      expect(janOnly, <Payment>[january]);
    });

    test('breakdownByCategoryPerCurrency groups by tag per currency', () {
      final Payment salary = Payment.create(
        title: 'Salary',
        amountMinor: 100_000,
        currencyCode: 'USD',
        direction: PaymentDirection.income,
        status: PaymentStatus.completed,
      )..id = 1;
      final Payment rent = Payment.create(
        title: 'Rent',
        amountMinor: 40_000,
        currencyCode: 'USD',
        direction: PaymentDirection.expense,
        status: PaymentStatus.completed,
      )..id = 2;
      final Payment untagged = Payment.create(
        title: 'Cash',
        amountMinor: 5_000,
        currencyCode: 'USD',
        direction: PaymentDirection.expense,
        status: PaymentStatus.completed,
      )..id = 3;

      final Map<String, List<CategoryPaymentBreakdown>> breakdown =
          PaymentAggregates.breakdownByCategoryPerCurrency(
        <Payment>[salary, rent, untagged],
        <int, List<int>>{
          1: <int>[10],
          2: <int>[20],
          3: <int>[],
        },
        statusFilter: PaymentStatus.completed,
      );

      final List<CategoryPaymentBreakdown> usd = breakdown['USD']!;
      expect(usd.length, 3);

      final CategoryPaymentBreakdown work = usd.firstWhere(
        (CategoryPaymentBreakdown row) => row.categoryId == 10,
      );
      expect(work.incomeMinor, 100_000);
      expect(work.expenseMinor, 0);

      final CategoryPaymentBreakdown home = usd.firstWhere(
        (CategoryPaymentBreakdown row) => row.categoryId == 20,
      );
      expect(home.expenseMinor, 40_000);

      final CategoryPaymentBreakdown uncategorized = usd.firstWhere(
        (CategoryPaymentBreakdown row) => row.categoryId == null,
      );
      expect(uncategorized.expenseMinor, 5_000);
    });

    test('breakdownByCategoryPerCurrency duplicates multi-tagged payments', () {
      final Payment shared = Payment.create(
        title: 'Shared',
        amountMinor: 3_000,
        currencyCode: 'EUR',
        direction: PaymentDirection.expense,
        status: PaymentStatus.completed,
      )..id = 5;

      final Map<String, List<CategoryPaymentBreakdown>> breakdown =
          PaymentAggregates.breakdownByCategoryPerCurrency(
        <Payment>[shared],
        <int, List<int>>{5: <int>[1, 2]},
        statusFilter: PaymentStatus.completed,
      );

      final List<CategoryPaymentBreakdown> eur = breakdown['EUR']!;
      expect(eur.length, 2);
      expect(eur.every((CategoryPaymentBreakdown row) => row.expenseMinor == 3_000),
          isTrue);
    });
  });
}
