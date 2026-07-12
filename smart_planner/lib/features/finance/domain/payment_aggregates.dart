import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

/// Per-currency totals for a payment list (no FX conversion).
class CurrencyPaymentTotals {
  const CurrencyPaymentTotals({
    required this.currencyCode,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final String currencyCode;
  final int incomeMinor;
  final int expenseMinor;

  int get balanceMinor => incomeMinor - expenseMinor;
}

/// Per-category income/expense within one currency (completed payments).
class CategoryPaymentBreakdown {
  const CategoryPaymentBreakdown({
    this.categoryId,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  /// `null` = uncategorized (no tags on the payment).
  final int? categoryId;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;

  bool get isEmpty => incomeMinor == 0 && expenseMinor == 0;
}

/// Pure domain helpers for finance summaries.
class PaymentAggregates {
  PaymentAggregates._();

  /// Sentinel key for payments without category tags in [breakdownByCategoryPerCurrency].
  static const int uncategorizedCategoryId = -1;

  /// Sums completed payments grouped by [Payment.currencyCode].
  static Map<String, CurrencyPaymentTotals> totalsByCurrency(
    Iterable<Payment> payments, {
    PaymentStatus? statusFilter,
  }) {
    final Map<String, _MutableTotals> buckets = <String, _MutableTotals>{};

    for (final Payment payment in payments) {
      if (statusFilter != null && payment.status != statusFilter) {
        continue;
      }
      if (payment.status == PaymentStatus.cancelled) {
        continue;
      }

      final String code = payment.currencyCode.toUpperCase();
      final _MutableTotals bucket =
          buckets.putIfAbsent(code, () => _MutableTotals(code));

      switch (payment.direction) {
        case PaymentDirection.income:
          bucket.incomeMinor += payment.amountMinor;
        case PaymentDirection.expense:
          bucket.expenseMinor += payment.amountMinor;
      }
    }

    return Map<String, CurrencyPaymentTotals>.fromEntries(
      buckets.entries.map(
        (MapEntry<String, _MutableTotals> entry) => MapEntry<String, CurrencyPaymentTotals>(
          entry.key,
          CurrencyPaymentTotals(
            currencyCode: entry.value.currencyCode,
            incomeMinor: entry.value.incomeMinor,
            expenseMinor: entry.value.expenseMinor,
          ),
        ),
      ),
    );
  }

  /// Groups completed payments by [Payment.currencyCode] and category tag.
  ///
  /// [categoryIdsByPaymentId] maps payment id → category ids from [CategoryLink].
  /// Payments with multiple tags contribute the **full** amount to each tag
  /// (analytics-style; subtotals may exceed currency totals).
  /// Untagged payments go to [uncategorizedCategoryId].
  static Map<String, List<CategoryPaymentBreakdown>> breakdownByCategoryPerCurrency(
    Iterable<Payment> payments,
    Map<int, List<int>> categoryIdsByPaymentId, {
    PaymentStatus? statusFilter,
  }) {
    final Map<String, Map<int, _CategoryMutable>> buckets =
        <String, Map<int, _CategoryMutable>>{};

    for (final Payment payment in payments) {
      if (statusFilter != null && payment.status != statusFilter) {
        continue;
      }
      if (payment.status == PaymentStatus.cancelled) {
        continue;
      }

      final String code = payment.currencyCode.toUpperCase();
      final Map<int, _CategoryMutable> perCategory =
          buckets.putIfAbsent(code, () => <int, _CategoryMutable>{});

      final List<int> categoryIds =
          categoryIdsByPaymentId[payment.id] ?? const <int>[];
      final List<int> targets = categoryIds.isEmpty
          ? <int>[uncategorizedCategoryId]
          : categoryIds;

      for (final int categoryId in targets) {
        final _CategoryMutable row = perCategory.putIfAbsent(
          categoryId,
          () => _CategoryMutable(categoryId),
        );
        switch (payment.direction) {
          case PaymentDirection.income:
            row.incomeMinor += payment.amountMinor;
          case PaymentDirection.expense:
            row.expenseMinor += payment.amountMinor;
        }
      }
    }

    return Map<String, List<CategoryPaymentBreakdown>>.fromEntries(
      buckets.entries.map(
        (MapEntry<String, Map<int, _CategoryMutable>> entry) {
          final List<CategoryPaymentBreakdown> rows = entry.value.values
              .map(
                (_CategoryMutable row) => CategoryPaymentBreakdown(
                  categoryId: row.categoryId == uncategorizedCategoryId
                      ? null
                      : row.categoryId,
                  incomeMinor: row.incomeMinor,
                  expenseMinor: row.expenseMinor,
                ),
              )
              .where((CategoryPaymentBreakdown row) => !row.isEmpty)
              .toList(growable: false);
          rows.sort(
            (CategoryPaymentBreakdown a, CategoryPaymentBreakdown b) {
              final int aTotal = a.incomeMinor + a.expenseMinor;
              final int bTotal = b.incomeMinor + b.expenseMinor;
              final int byAmount = bTotal.compareTo(aTotal);
              if (byAmount != 0) {
                return byAmount;
              }
              final int? aId = a.categoryId;
              final int? bId = b.categoryId;
              if (aId == null && bId != null) {
                return 1;
              }
              if (aId != null && bId == null) {
                return -1;
              }
              return (aId ?? 0).compareTo(bId ?? 0);
            },
          );
          return MapEntry<String, List<CategoryPaymentBreakdown>>(
            entry.key,
            rows,
          );
        },
      ),
    );
  }

  /// Filters payments whose [Payment.occurredAt] falls in [year]/[month] (local).
  static List<Payment> forMonth(
    Iterable<Payment> payments, {
    required int year,
    required int month,
  }) {
    return payments
        .where(
          (Payment payment) =>
              payment.occurredAt.year == year &&
              payment.occurredAt.month == month,
        )
        .toList(growable: false);
  }
}

class _MutableTotals {
  _MutableTotals(this.currencyCode);

  final String currencyCode;
  int incomeMinor = 0;
  int expenseMinor = 0;
}

class _CategoryMutable {
  _CategoryMutable(this.categoryId);

  final int categoryId;
  int incomeMinor = 0;
  int expenseMinor = 0;
}
