import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/presentation/widgets/payment_form_sheet.dart';
import 'package:smart_planner/features/finance/presentation/widgets/payment_list_tile.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_section_header.dart';

/// Linked payments block on task / event detail screens.
class LinkedPaymentsSection extends StatelessWidget {
  const LinkedPaymentsSection({
    required this.payments,
    required this.onAdd,
    required this.onToggleStatus,
    required this.onOpenPayment,
    super.key,
  });

  final List<Payment> payments;
  final VoidCallback onAdd;
  final ValueChanged<Id> onToggleStatus;
  final void Function(Payment payment) onOpenPayment;

  static Future<bool?> openCreatePayment({
    required BuildContext context,
    int? linkedTaskId,
    int? linkedEventId,
    DateTime? initialOccurredAt,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentFormSheet(
        linkedTaskId: linkedTaskId,
        linkedEventId: linkedEventId,
        initialOccurredAt: initialOccurredAt,
      ),
    );
  }

  static Future<bool?> openEditPayment({
    required BuildContext context,
    required Payment payment,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentFormSheet(paymentToEdit: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TaskTileSectionHeader(
          icon: Icons.payments_outlined,
          title: 'detail_payments_title'.tr(),
          trailing: payments.isNotEmpty ? '${payments.length}' : null,
          iconColor: colors.tertiary,
        ),
        const SizedBox(height: 8),
        if (payments.isEmpty)
          Text(
            'detail_payments_empty'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...payments.map(
            (Payment payment) => PaymentListTile(
              payment: payment,
              compact: true,
              onToggleStatus: onToggleStatus,
              onTap: () => onOpenPayment(payment),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('detail_payments_add'.tr()),
          ),
        ),
      ],
    );
  }
}
