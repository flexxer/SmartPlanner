import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/theme/app_theme.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/money.dart';
import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

/// Payment row with planned ↔ completed checkbox on [FinanceScreen].
class PaymentListTile extends StatelessWidget {
  const PaymentListTile({
    required this.payment,
    required this.onToggleStatus,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final Payment payment;
  final ValueChanged<Id> onToggleStatus;
  final VoidCallback onTap;
  final bool compact;

  bool get _isCompleted => payment.status == PaymentStatus.completed;

  bool get _checkboxEnabled =>
      payment.status == PaymentStatus.planned ||
      payment.status == PaymentStatus.completed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isExpense = payment.direction == PaymentDirection.expense;
    final Color amountColor = isExpense ? colors.error : colors.tertiary;

    return Card(
      margin: compact
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colors.surface,
      shape: AppTheme.insetCardShape(colors),
      child: ListTile(
        leading: _checkboxEnabled
            ? Checkbox(
                value: _isCompleted,
                onChanged: (_) => onToggleStatus(payment.id),
              )
            : const SizedBox(width: 24),
        title: Text(
          payment.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: _isCompleted ? TextDecoration.lineThrough : null,
            color: _isCompleted
                ? colors.onSurface.withValues(alpha: 0.55)
                : null,
          ),
        ),
        subtitle: Text(
          L10n.dateFormat('d MMM yyyy', context: context)
              .format(payment.occurredAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          formatSignedMoneyMinor(
            payment.amountMinor,
            payment.currencyCode,
            isExpense: isExpense,
          ),
          style: theme.textTheme.titleSmall?.copyWith(
            color: _isCompleted
                ? amountColor.withValues(alpha: 0.55)
                : amountColor,
            fontWeight: FontWeight.w700,
            decoration: _isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
