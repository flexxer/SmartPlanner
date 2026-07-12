import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/theme/app_theme.dart';
import 'package:smart_planner/features/categories/domain/category_color.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/finance/domain/money.dart';
import 'package:smart_planner/features/finance/domain/payment_aggregates.dart';

/// Monthly income / expense / balance grouped by currency (no FX).
class FinanceSummaryHeader extends StatelessWidget {
  const FinanceSummaryHeader({
    required this.monthLabel,
    required this.totalsByCurrency,
    this.breakdownByCurrency = const <String, List<CategoryPaymentBreakdown>>{},
    this.categoriesById = const <int, Category>{},
    super.key,
  });

  final String monthLabel;
  final Map<String, CurrencyPaymentTotals> totalsByCurrency;
  final Map<String, List<CategoryPaymentBreakdown>> breakdownByCurrency;
  final Map<int, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (totalsByCurrency.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              monthLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'finance_summary_empty'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final List<String> codes = totalsByCurrency.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            monthLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...codes.map((String code) {
            final CurrencyPaymentTotals totals = totalsByCurrency[code]!;
            final List<CategoryPaymentBreakdown> breakdown =
                breakdownByCurrency[code] ?? const <CategoryPaymentBreakdown>[];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: AppTheme.groupedSectionDecoration(colors),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      code,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _SummaryLine(
                      label: 'finance_summary_income'.tr(),
                      value: formatMoneyMinor(
                        totals.incomeMinor,
                        code,
                      ),
                      valueColor: colors.tertiary,
                    ),
                    _SummaryLine(
                      label: 'finance_summary_expense'.tr(),
                      value: formatMoneyMinor(
                        totals.expenseMinor,
                        code,
                      ),
                      valueColor: colors.error,
                    ),
                    const Divider(height: 16),
                    _SummaryLine(
                      label: 'finance_summary_balance'.tr(),
                      value: formatSignedMoneyMinor(
                        totals.balanceMinor.abs(),
                        code,
                        isExpense: totals.balanceMinor < 0,
                      ),
                      valueColor: totals.balanceMinor >= 0
                          ? colors.primary
                          : colors.error,
                      emphasized: true,
                    ),
                    if (breakdown.isNotEmpty) ...<Widget>[
                      const Divider(height: 20),
                      Text(
                        'finance_summary_by_category'.tr(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...breakdown.map(
                        (CategoryPaymentBreakdown row) => _CategoryBreakdownTile(
                          label: _labelFor(row.categoryId),
                          accentColor: _accentFor(row.categoryId, colors),
                          currencyCode: code,
                          breakdown: row,
                          colors: colors,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _labelFor(int? categoryId) {
    if (categoryId == null) {
      return 'finance_category_uncategorized'.tr();
    }
    return categoriesById[categoryId]?.name ?? '#$categoryId';
  }

  Color _accentFor(int? categoryId, ColorScheme colors) {
    if (categoryId == null) {
      return colors.outline;
    }
    final Category? category = categoriesById[categoryId];
    if (category == null) {
      return colors.outline;
    }
    return categoryColorFromValue(category.colorValue);
  }
}

class _CategoryBreakdownTile extends StatelessWidget {
  const _CategoryBreakdownTile({
    required this.label,
    required this.accentColor,
    required this.currencyCode,
    required this.breakdown,
    required this.colors,
  });

  final String label;
  final Color accentColor;
  final String currencyCode;
  final CategoryPaymentBreakdown breakdown;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 6,
                backgroundColor: accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (breakdown.incomeMinor > 0)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _SummaryLine(
                label: 'finance_summary_income'.tr(),
                value: formatMoneyMinor(breakdown.incomeMinor, currencyCode),
                valueColor: colors.tertiary,
              ),
            ),
          if (breakdown.expenseMinor > 0)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _SummaryLine(
                label: 'finance_summary_expense'.tr(),
                value: formatMoneyMinor(breakdown.expenseMinor, currencyCode),
                valueColor: colors.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = emphasized
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    final TextStyle? valueStyle = emphasized
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
