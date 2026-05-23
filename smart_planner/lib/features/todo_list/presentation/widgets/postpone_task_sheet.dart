import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Выбор нового срока при переносе задачи.
class PostponeTaskSheet extends StatefulWidget {
  const PostponeTaskSheet({
    required this.task,
    required this.referenceDate,
    super.key,
  });

  final Task task;

  /// День, относительно которого считается «завтра» (выбранный день на дашборде).
  final DateTime referenceDate;

  @override
  State<PostponeTaskSheet> createState() => _PostponeTaskSheetState();
}

class _PostponeTaskSheetState extends State<PostponeTaskSheet> {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy', 'ru');

  late DateTime _pickedDate;

  DateTime get _tomorrow => AppDateUtils.startOfDay(widget.referenceDate).add(
        const Duration(days: 1),
      );

  @override
  void initState() {
    super.initState();
    _pickedDate = _tomorrow;
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('ru'),
    );
    if (date != null) {
      setState(() => _pickedDate = AppDateUtils.startOfDay(date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Task task = widget.task;
    final ThemeData theme = Theme.of(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final String? currentDue = task.dueDate != null
        ? _dateFormat.format(task.dueDate!)
        : null;

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
                'Перенести задачу',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (currentDue != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  'Текущий срок: $currentDue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_tomorrow),
                icon: const Icon(Icons.today_outlined),
                label: Text('На завтра (${_dateFormat.format(_tomorrow)})'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text('Другая дата: ${_dateFormat.format(_pickedDate)}'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_pickedDate),
                child: const Text('Перенести'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
