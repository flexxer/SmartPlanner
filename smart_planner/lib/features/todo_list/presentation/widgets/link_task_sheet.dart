import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Pick an existing root task to link as a child of [parentTaskId].
class LinkTaskSheet extends StatefulWidget {
  const LinkTaskSheet({
    required this.repository,
    required this.parentTaskId,
    required this.parentTitle,
    super.key,
  });

  final TodoRepository repository;
  final Id parentTaskId;
  final String parentTitle;

  @override
  State<LinkTaskSheet> createState() => _LinkTaskSheetState();
}

class _LinkTaskSheetState extends State<LinkTaskSheet> {
  List<Task> _candidates = <Task>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Task> tasks =
          await widget.repository.getTasksAttachableToParent(
        widget.parentTaskId,
      );
      if (mounted) {
        setState(() {
          _candidates = tasks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _link(Task child) async {
    final bool ok = await widget.repository.attachTaskToParent(
      childTaskId: child.id,
      parentTaskId: widget.parentTaskId,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось привязать задачу'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Привязать к задаче',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.parentTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text('Ошибка: $_error')
              else if (_candidates.isEmpty)
                const Text(
                  'Нет доступных задач. Создайте задачу без родителя '
                  'или отвяжите её от другой.',
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _candidates.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Task task = _candidates[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(task.title),
                        subtitle: task.dueDate != null
                            ? Text(
                                'Срок: ${task.dueDate!.day}.'
                                '${task.dueDate!.month}.'
                                '${task.dueDate!.year}',
                              )
                            : const Text('Без срока'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _link(task),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
