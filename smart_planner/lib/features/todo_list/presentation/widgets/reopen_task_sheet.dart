import 'package:flutter/material.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Выбор нового срока для копии выполненной задачи.
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

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('ru'),
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
                'Переоткрыть задачу',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Будет создана новая задача с тем же названием. '
                'Выполненная запись останется в архиве.',
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
                        _priorityLabel(task.priority),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Icons.event),
                label: Text('Новый срок: ${_formatDate(_dueDate)}'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_dueDate),
                icon: const Icon(Icons.replay),
                label: const Text('Создать снова'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => 'Низкий приоритет',
      TaskPriority.medium => 'Средний приоритет',
      TaskPriority.high => 'Высокий приоритет',
      TaskPriority.urgent => 'Срочный приоритет',
    };
  }

  static String _formatDate(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }
}
