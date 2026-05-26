import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Pick a new due date when reopening a completed task.
class ReopenTaskSheet extends StatefulWidget {
  const ReopenTaskSheet({
    required this.sourceTask,
    super.key,
  });

  final Task sourceTask;

  @override
  State<ReopenTaskSheet> createState() => _ReopenTaskSheetState();
}

class _ReopenTaskSheetState extends State<ReopenTaskSheet> {
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = AppDateUtils.startOfDay(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return L10n.dateFormat('dd.MM.yyyy', context: context).format(date);
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: context.locale,
    );
    if (picked != null) {
      setState(() => _dueDate = AppDateUtils.startOfDay(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Task task = widget.sourceTask;
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'reopen_sheet_title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'reopen_sheet_body'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: task.description != null &&
                        task.description!.isNotEmpty
                    ? Text(task.description!)
                    : Text(
                        L10n.priorityLabelWithSuffix(task.priority),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Icons.event),
                label: Text(
                  'reopen_new_due'.tr(
                    namedArgs: <String, String>{'date': _formatDate(_dueDate)},
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_dueDate),
                icon: const Icon(Icons.replay),
                label: Text('reopen_create_again'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
