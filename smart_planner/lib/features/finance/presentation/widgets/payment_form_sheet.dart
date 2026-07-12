import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/finance/currency_preferences_repository.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/presentation/widgets/confirm_delete_record.dart';
import 'package:smart_planner/core/presentation/widgets/form_sheet_scaffold.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';
import 'package:smart_planner/features/categories/presentation/widgets/category_tags_field.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/money.dart';
import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';
import 'package:smart_planner/features/finance/domain/repositories/payment_repository.dart';

/// Create or edit a local [Payment].
class PaymentFormSheet extends StatefulWidget {
  const PaymentFormSheet({
    this.paymentToEdit,
    this.initialOccurredAt,
    this.linkedTaskId,
    this.linkedEventId,
    super.key,
  });

  final Payment? paymentToEdit;
  final DateTime? initialOccurredAt;
  final int? linkedTaskId;
  final int? linkedEventId;

  bool get isEditing => paymentToEdit != null;

  @override
  State<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<PaymentFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late PaymentDirection _direction;
  late DateTime _occurredAt;
  late String _currencyCode;
  List<Id> _selectedCategoryIds = <Id>[];
  bool _defaultsLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Payment? existing = widget.paymentToEdit;
    if (existing != null) {
      _titleController = TextEditingController(text: existing.title);
      _amountController = TextEditingController(
        text: minorToAmount(existing.amountMinor, existing.currencyCode)
            .toString(),
      );
      _noteController = TextEditingController(text: existing.note ?? '');
      _direction = existing.direction;
      _occurredAt = existing.occurredAt;
      _currencyCode = existing.currencyCode;
      _loadCategoryTags(existing.id);
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _direction = PaymentDirection.expense;
      _occurredAt = widget.initialOccurredAt ?? DateTime.now();
      _loadDefaults();
    }
  }

  Future<void> _loadDefaults() async {
    final String code =
        await context.read<CurrencyPreferencesRepository>().getDefaultCurrencyCode();
    final CategoryTagService tagService = context.read<CategoryTagService>();
    List<Id> prefilledTags = <Id>[];

    if (widget.linkedTaskId != null) {
      prefilledTags = await tagService.getTagIds(
        entityType: TaggedEntityType.task,
        entityId: widget.linkedTaskId!,
      );
    } else if (widget.linkedEventId != null) {
      prefilledTags = await tagService.getTagIds(
        entityType: TaggedEntityType.calendarEvent,
        entityId: widget.linkedEventId!,
      );
    }

    if (mounted) {
      setState(() {
        _currencyCode = code;
        _selectedCategoryIds = prefilledTags;
        _defaultsLoaded = true;
      });
    }
  }

  Future<void> _loadCategoryTags(Id paymentId) async {
    final List<Id> ids = await context.read<CategoryTagService>().getTagIds(
          entityType: TaggedEntityType.payment,
          entityId: paymentId,
        );
    if (mounted) {
      setState(() {
        _selectedCategoryIds = ids;
        _defaultsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _occurredAt = picked);
    }
  }

  Future<void> _persistCategoryTags(Id paymentId) async {
    await context.read<CategoryTagService>().setTags(
          entityType: TaggedEntityType.payment,
          entityId: paymentId,
          categoryIds: _selectedCategoryIds,
        );
  }

  Future<void> _deletePayment() async {
    final Payment? payment = widget.paymentToEdit;
    if (payment == null) {
      return;
    }
    final bool confirmed = await confirmDeleteRecord(context);
    if (!confirmed || !mounted) {
      return;
    }

    final PaymentRepository repository = context.read<PaymentRepository>();
    final CategoryTagService tagService = context.read<CategoryTagService>();
    await tagService.deleteLinksForEntity(
      entityType: TaggedEntityType.payment,
      entityId: payment.id,
    );
    await repository.delete(payment.id);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment_enter_title'.tr())),
      );
      return;
    }

    final String amountText = _amountController.text.trim().replaceAll(',', '.');
    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment_invalid_amount'.tr())),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final PaymentRepository repository = context.read<PaymentRepository>();
      final int amountMinor = amountToMinor(amount, _currencyCode);
      final String? note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (widget.isEditing) {
        final Payment payment = widget.paymentToEdit!
          ..title = title
          ..amountMinor = amountMinor
          ..currencyCode = _currencyCode
          ..direction = _direction
          ..occurredAt = _occurredAt
          ..note = note;
        await repository.save(payment);
        await _persistCategoryTags(payment.id);
      } else {
        final Id id = await repository.save(
          Payment.create(
            title: title,
            amountMinor: amountMinor,
            currencyCode: _currencyCode,
            direction: _direction,
            occurredAt: _occurredAt,
            note: note,
            linkedTaskId: widget.linkedTaskId,
            linkedEventId: widget.linkedEventId,
          ),
        );
        await _persistCategoryTags(id);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'common_error_with_details'.tr(
                namedArgs: <String, String>{'details': '$e'},
              ),
            ),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_defaultsLoaded) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FormSheetScaffold(
      title: widget.isEditing ? 'payment_edit'.tr() : 'payment_new'.tr(),
      onDelete: widget.isEditing ? _deletePayment : null,
      deleteEnabled: !_saving,
      children: <Widget>[
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'payment_field_title'.tr(),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          autofocus: !widget.isEditing,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'payment_field_amount'.tr(),
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: CurrencyPreferencesRepository.supportedCurrencyCodes
                  .contains(_currencyCode)
              ? _currencyCode
              : CurrencyPreferencesRepository.defaultCurrencyCode,
          decoration: InputDecoration(
            labelText: 'payment_field_currency'.tr(),
            border: const OutlineInputBorder(),
          ),
          items: CurrencyPreferencesRepository.supportedCurrencyCodes
              .map(
                (String code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(code),
                ),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (String? code) {
                  if (code != null) {
                    setState(() => _currencyCode = code);
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PaymentDirection>(
          value: _direction,
          decoration: InputDecoration(
            labelText: 'payment_field_direction'.tr(),
            border: const OutlineInputBorder(),
          ),
          items: PaymentDirection.values
              .map(
                (PaymentDirection direction) =>
                    DropdownMenuItem<PaymentDirection>(
                  value: direction,
                  child: Text(_directionLabel(direction)),
                ),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (PaymentDirection? value) {
                  if (value != null) {
                    setState(() => _direction = value);
                  }
                },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickDate,
          icon: const Icon(Icons.event_outlined),
          label: Text(
            'payment_field_date'.tr(
              namedArgs: <String, String>{
                'date': L10n.dateFormat('d MMM yyyy', context: context)
                    .format(_occurredAt),
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: 'payment_field_note'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CategoryTagsField(
          selectedCategoryIds: _selectedCategoryIds,
          onSelectionChanged: (List<Id> ids) {
            setState(() => _selectedCategoryIds = ids);
          },
        ),
        const SizedBox(height: 16),
        FormSheetSaveButton(
          label: 'common_save'.tr(),
          enabled: !_saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  String _directionLabel(PaymentDirection direction) {
    return switch (direction) {
      PaymentDirection.expense => 'payment_direction_expense'.tr(),
      PaymentDirection.income => 'payment_direction_income'.tr(),
    };
  }
}
