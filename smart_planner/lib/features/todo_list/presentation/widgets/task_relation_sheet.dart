import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// What the user is linking and to which anchor (parent task or calendar event).
sealed class TaskRelationTarget {
  const TaskRelationTarget();
}

/// Add or link tasks as children of [parentTaskId].
final class TaskRelationParentTarget extends TaskRelationTarget {
  const TaskRelationParentTarget({
    required this.parentTaskId,
    required this.title,
    required this.selectedDate,
  });

  final Id parentTaskId;
  final String title;
  final DateTime selectedDate;
}

/// Add or link tasks to [event].
final class TaskRelationEventTarget extends TaskRelationTarget {
  const TaskRelationEventTarget({
    required this.event,
    required this.selectedDate,
  });

  final CalendarEvent event;
  final DateTime selectedDate;

  String get title => event.title;
}

/// Link [task] to one of [dayEvents].
final class TaskRelationPickEventTarget extends TaskRelationTarget {
  const TaskRelationPickEventTarget({
    required this.task,
    required this.dayEvents,
  });

  final Task task;
  final List<CalendarEvent> dayEvents;
}

/// Result returned when the user completes an action in [TaskRelationSheet].
sealed class TaskRelationSheetResult {
  const TaskRelationSheetResult();
}

final class TaskRelationLinkedExistingTask extends TaskRelationSheetResult {
  const TaskRelationLinkedExistingTask(this.taskId);

  final Id taskId;
}

final class TaskRelationPickedEvent extends TaskRelationSheetResult {
  const TaskRelationPickedEvent(this.event);

  final CalendarEvent event;
}

final class TaskRelationCreateTaskRequested extends TaskRelationSheetResult {
  const TaskRelationCreateTaskRequested({this.template});

  final UiTemplate? template;
}

/// Unified sheet: template / new task / pick existing (task or event).
class TaskRelationSheet extends StatefulWidget {
  const TaskRelationSheet({
    required this.target,
    super.key,
  });

  final TaskRelationTarget target;

  @override
  State<TaskRelationSheet> createState() => _TaskRelationSheetState();
}

class _TaskRelationSheetState extends State<TaskRelationSheet> {
  bool _loading = true;
  String? _error;
  List<Task> _taskCandidates = <Task>[];
  List<UiTemplate> _templates = <UiTemplate>[];
  bool _showTemplates = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final TodoRepository repository = context.read<TodoRepository>();
      final UiTemplateRepository? templateRepository =
          widget.target is! TaskRelationPickEventTarget
              ? context.read<UiTemplateRepository>()
              : null;
      final TaskRelationTarget target = widget.target;

      switch (target) {
        case TaskRelationParentTarget(:final Id parentTaskId):
          _taskCandidates =
              await repository.getTasksAttachableToParent(parentTaskId);
        case TaskRelationEventTarget(:final CalendarEvent event):
          _taskCandidates =
              await repository.getTasksAttachableToEvent(event);
        case TaskRelationPickEventTarget():
          _taskCandidates = <Task>[];
      }

      if (templateRepository != null) {
        _templates = await templateRepository.getAll();
      }

      if (mounted) {
        setState(() => _loading = false);
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

  String _sheetTitle() {
    return switch (widget.target) {
      TaskRelationParentTarget(:final String title) =>
        'task_relation_sheet_title_parent'.tr(
          namedArgs: <String, String>{'title': title},
        ),
      TaskRelationEventTarget(:final String title) =>
        'task_relation_sheet_title_event'.tr(
          namedArgs: <String, String>{'title': title},
        ),
      TaskRelationPickEventTarget(:final Task task) =>
        'task_relation_sheet_title_pick_event'.tr(
          namedArgs: <String, String>{'title': task.title},
        ),
    };
  }

  void _requestCreate({UiTemplate? template}) {
    Navigator.of(context).pop(
      TaskRelationCreateTaskRequested(template: template),
    );
  }

  void _pickExistingTask(Task task) {
    Navigator.of(context).pop(TaskRelationLinkedExistingTask(task.id));
  }

  void _pickEvent(CalendarEvent event) {
    Navigator.of(context).pop(TaskRelationPickedEvent(event));
  }

  String _formatDue(DateTime due) {
    return L10n.dateFormat('dd.MM.yyyy', context: context).format(due);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final double maxListHeight = MediaQuery.sizeOf(context).height * 0.35;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _showTemplates
                    ? 'task_relation_templates_title'.tr()
                    : _sheetTitle(),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(
                  'common_error_with_details'.tr(
                    namedArgs: <String, String>{'details': _error!},
                  ),
                )
              else if (_showTemplates)
                _buildTemplateList(theme, colors)
              else ...<Widget>[
                if (widget.target is! TaskRelationPickEventTarget) ...<Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => _requestCreate(),
                    icon: const Icon(Icons.add),
                    label: Text('task_relation_create_new'.tr()),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showTemplates = true),
                    icon: const Icon(Icons.layers_outlined),
                    label: Text('task_relation_from_template'.tr()),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  widget.target is TaskRelationPickEventTarget
                      ? 'task_relation_existing_events_header'.tr()
                      : 'task_relation_existing_tasks_header'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxListHeight),
                    child: _buildExistingList(theme, colors),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => setState(() => _showTemplates = false),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'task_relation_back'.tr(),
          ),
        ),
        if (_templates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'task_relation_templates_empty'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _templates.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final UiTemplate template = _templates[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.outlineVariant),
                  ),
                  title: Text(template.title),
                  subtitle: template.templateDescription?.trim().isNotEmpty ==
                          true
                      ? Text(template.templateDescription!.trim())
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _requestCreate(template: template),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExistingList(ThemeData theme, ColorScheme colors) {
    return switch (widget.target) {
      TaskRelationPickEventTarget(:final List<CalendarEvent> dayEvents) =>
        _buildEventList(dayEvents, colors),
      _ => _buildTaskList(colors),
    };
  }

  Widget _buildTaskList(ColorScheme colors) {
    if (_taskCandidates.isEmpty) {
      return SingleChildScrollView(
        child: Text('task_relation_existing_tasks_empty'.tr()),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _taskCandidates.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Task task = _taskCandidates[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(task.title),
          subtitle: task.dueDate != null
              ? Text(
                  'due_label'.tr(
                    namedArgs: <String, String>{
                      'date': _formatDue(task.dueDate!),
                    },
                  ),
                )
              : Text('no_due_date'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickExistingTask(task),
        );
      },
    );
  }

  Widget _buildEventList(List<CalendarEvent> events, ColorScheme colors) {
    if (events.isEmpty) {
      return SingleChildScrollView(
        child: Text('link_event_sheet_empty'.tr()),
      );
    }

    final DateFormat timeFormat = L10n.dateFormat('Hm', context: context);

    return ListView.separated(
      shrinkWrap: true,
      itemCount: events.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final CalendarEvent event = events[index];
        final Color accent = CalendarContextColors.accentFor(
          context,
          calendarId: event.calendarId,
          fallbackColorValue: event.colorValue,
        );
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.outlineVariant),
          ),
          leading: VerticalDivider(
            width: 4,
            thickness: 4,
            color: accent,
          ),
          title: Text(event.title),
          subtitle: Text(
            '${timeFormat.format(event.start)} – ${timeFormat.format(event.end)}',
          ),
          onTap: () => _pickEvent(event),
        );
      },
    );
  }
}
