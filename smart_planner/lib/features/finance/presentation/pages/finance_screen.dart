import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_aggregates.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';
import 'package:smart_planner/features/finance/domain/repositories/payment_repository.dart';
import 'package:smart_planner/features/finance/presentation/widgets/finance_summary_header.dart';
import 'package:smart_planner/features/finance/presentation/widgets/payment_form_sheet.dart';
import 'package:smart_planner/features/finance/presentation/widgets/payment_list_tile.dart';

/// Payments list and monthly summary (dashboard AppBar entry).
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  DateTime _focusedMonth = AppDateUtils.startOfDay(DateTime.now());
  List<Payment> _payments = <Payment>[];
  Map<int, List<Id>> _categoryIdsByPaymentId = <int, List<Id>>{};
  Map<int, Category> _categoriesById = <int, Category>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final PaymentRepository repository = context.read<PaymentRepository>();
    final CategoryTagService tagService = context.read<CategoryTagService>();
    final CategoryRepository categoryRepository =
        context.read<CategoryRepository>();
    final List<Payment> monthPayments = await repository.getForMonth(
      year: _focusedMonth.year,
      month: _focusedMonth.month,
    );
    final Map<int, List<Id>> categoryIdsByPaymentId = <int, List<Id>>{};
    for (final Payment payment in monthPayments) {
      categoryIdsByPaymentId[payment.id] = await tagService.getTagIds(
        entityType: TaggedEntityType.payment,
        entityId: payment.id,
      );
    }
    final List<Category> categories = await categoryRepository.getActive();
    final Map<int, Category> categoriesById = <int, Category>{
      for (final Category category in categories) category.id: category,
    };
    if (!mounted) {
      return;
    }
    setState(() {
      _payments = monthPayments;
      _categoryIdsByPaymentId = categoryIdsByPaymentId;
      _categoriesById = categoriesById;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
      );
    });
    _reload();
  }

  Future<void> _openForm({Payment? payment}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentFormSheet(
        paymentToEdit: payment,
        initialOccurredAt: _focusedMonth,
      ),
    );
    if (saved == true && mounted) {
      await _reload();
    }
  }

  Future<void> _toggleStatus(Id paymentId) async {
    await context.read<PaymentRepository>().togglePlannedCompleted(paymentId);
    await _reload();
  }

  String _monthLabel(BuildContext context) {
    return L10n.dateFormat('MMMM yyyy', context: context).format(_focusedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, CurrencyPaymentTotals> totals =
        PaymentAggregates.totalsByCurrency(
      _payments,
      statusFilter: PaymentStatus.completed,
    );
    final Map<String, List<CategoryPaymentBreakdown>> breakdown =
        PaymentAggregates.breakdownByCategoryPerCurrency(
      _payments,
      _categoryIdsByPaymentId,
      statusFilter: PaymentStatus.completed,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('finance_screen_title'.tr()),
        actions: <Widget>[
          IconButton(
            tooltip: 'finance_prev_month'.tr(),
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'finance_next_month'.tr(),
            onPressed: () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: FinanceSummaryHeader(
                      monthLabel: _monthLabel(context),
                      totalsByCurrency: totals,
                      breakdownByCurrency: breakdown,
                      categoriesById: _categoriesById,
                    ),
                  ),
                  if (_payments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyFinanceBody(
                        onCreate: () => _openForm(),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final Payment payment = _payments[index];
                          return PaymentListTile(
                            payment: payment,
                            onToggleStatus: _toggleStatus,
                            onTap: () => _openForm(payment: payment),
                          );
                        },
                        childCount: _payments.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text('finance_new_payment'.tr()),
      ),
    );
  }
}

class _EmptyFinanceBody extends StatelessWidget {
  const _EmptyFinanceBody({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'finance_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'finance_empty_body'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text('finance_new_payment'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
