import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Bottom sheet listing tasks linked to a [CalendarEvent].
class EventLinkedTasksSheet extends StatefulWidget {
  const EventLinkedTasksSheet({
    required this.event,
    required this.localCalendarRepository,
    required this.onAddTask,
    required this.onToggleTaskCompletion,
    required this.onTaskSelected,
    super.key,
  });

  final CalendarEvent event;
  final LocalCalendarEventRepository localCalendarRepository;
  final VoidCallback onAddTask;
  final void Function(Id taskId) onToggleTaskCompletion;
  final void Function(Id taskId) onTaskSelected;

  @override
  State<EventLinkedTasksSheet> createState() => _EventLinkedTasksSheetState();
}

class _EventLinkedTasksSheetState extends State<EventLinkedTasksSheet> {
  List<Task> _linkedTasks = <Task>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Task> tasks =
        await widget.localCalendarRepository.getLinkedTasks(widget.event);
    if (mounted) {
      setState(() {
        _linkedTasks = tasks;
        _loading = false;
      });
    }
  }

  String _formatDue(DateTime due) {
    return L10n.dateFormat('dd.MM.yyyy', context: context).format(due);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.event.title,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'events_linked_tasks'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_linkedTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'events_no_linked_tasks'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _linkedTasks.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final Task task = _linkedTasks[index];
                    return InkWell(
                      onTap: () => widget.onTaskSelected(task.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Checkbox(
                              value: task.isCompleted,
                              onChanged: (_) {
                                widget.onToggleTaskCompletion(task.id);
                                setState(() {
                                  task.isCompleted = !task.isCompleted;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    task.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? colors.onSurfaceVariant
                                          : null,
                                    ),
                                  ),
                                  if (task.dueDate != null)
                                    Text(
                                      'due_label'.tr(
                                        namedArgs: <String, String>{
                                          'date': _formatDue(task.dueDate!),
                                        },
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onAddTask,
              icon: const Icon(Icons.link),
              label: Text('task_relation_button'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
