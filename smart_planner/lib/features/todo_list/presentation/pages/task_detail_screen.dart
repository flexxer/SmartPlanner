import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/presentation/attachment_coordinator.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_badges_row.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_icon.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_tile_list_context.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_detail_child_tasks_section.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/ui_template_factory.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_detail_row.dart';

/// Full-screen task details (attachments, checklists, reorderable subtasks).
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    required this.taskId,
    required this.selectedDate,
    super.key,
  });

  final Id taskId;
  final DateTime selectedDate;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();

}

class _TaskDetailScreenState extends State<TaskDetailScreen> {

  Task? _task;
  List<TaskAttachment> _attachments = <TaskAttachment>[];
  List<Task> _activeChildren = <Task>[];
  List<Task> _completedChildren = <Task>[];
  int _completedChildCount = 0;
  int _totalChildCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final TodoRepository todoRepository = context.read<TodoRepository>();
    final TaskAttachmentRepository attachmentRepository =
        context.read<TaskAttachmentRepository>();

    final Task? task = await todoRepository.getTaskById(widget.taskId);
    if (!mounted) {
      return;
    }
    if (task == null) {
      Navigator.of(context).pop();
      return;
    }

    final List<TaskAttachment> attachments =
        await attachmentRepository.getAttachmentsForTask(widget.taskId);
    final List<Task> allChildren =
        await todoRepository.getAllChildTasks(widget.taskId);
    allChildren.sort(TodoRepository.compareChildTasks);

    final List<Task> active = allChildren
        .where((Task t) => !t.isCompleted)
        .toList(growable: false);
    final List<Task> completed = allChildren
        .where((Task t) => t.isCompleted)
        .toList(growable: false);

    setState(() {
      _task = task;
      _attachments = attachments;
      _activeChildren = active;
      _completedChildren = completed;
      _completedChildCount = completed.length;
      _totalChildCount = allChildren.length;
      _loading = false;
    });
  }

  void _onDashboardUpdated() {
    if (mounted) {
      _load();
    }
  }

  Future<void> _saveAsTemplate() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    final String? title = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _SaveTaskTemplateDialog(initialTitle: task.title);
      },
    );

    if (!mounted || title == null) {
      return;
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('task_enter_template_name'.tr())),
      );
      return;
    }

    final UiTemplateRepository repository =
        context.read<UiTemplateRepository>();
    final template = UiTemplateFactory.fromTask(
      task: task,
      attachments: _attachments,
      titleOverride: title,
    );
    await repository.save(template);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'task_template_saved'.tr(
              namedArgs: <String, String>{'title': title},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openEdit() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }
    final DashboardState blocState = context.read<DashboardBloc>().state;
    final List<String> selectedCalendarIds = blocState is DashboardLoaded
        ? blocState.selectedCalendarIds
        : const <String>[];
    await DashboardScreen.openEditTaskSheet(
      context,
      task: task,
      selectedCalendarIds: selectedCalendarIds,
    );
    _load();
  }

  void _reorderAttachments(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final List<TaskAttachment> items = List<TaskAttachment>.from(_attachments);
    final TaskAttachment moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _attachments = items);
    context.read<TaskAttachmentRepository>().reorder(
          items.map((TaskAttachment a) => a.id).toList(growable: false),
        );
  }

  void _reorderChildren(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final List<Task> items = List<Task>.from(_activeChildren);
    final Task moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _activeChildren = items);
    context.read<DashboardBloc>().add(
          ReorderChildTasks(
            parentTaskId: widget.taskId,
            orderedChildIds: items.map((Task t) => t.id).toList(growable: false),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final Task task = _task!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isOverdue = task.dynamicOverdueDays > 0;
    final String? description = task.description?.trim();
    final bool hasDescription =
        description != null && description.isNotEmpty;

    final DashboardState blocState = context.watch<DashboardBloc>().state;
    final Map<String, DeviceCalendarInfo> linkedCalendarsById =
        blocState is DashboardLoaded
            ? blocState.linkedCalendarsById
            : <String, DeviceCalendarInfo>{};
    final DeviceCalendarInfo? contextCalendar =
        linkedCalendarsById[task.calendarId];
    final CalendarEvent? linkedEvent = blocState is DashboardLoaded
        ? blocState.localCalendarEventById[task.linkedEventId]
        : null;

    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (DashboardState prev, DashboardState next) =>
          next is DashboardLoaded,
      listener: (BuildContext context, DashboardState state) =>
          _onDashboardUpdated(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('task_title'.tr()),
          actions: <Widget>[
            PopupMenuButton<String>(
              tooltip: 'task_menu_more'.tr(),
              onSelected: (String value) {
                if (value == 'save_template') {
                  _saveAsTemplate();
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'save_template',
                  child: Text('task_save_as_template'.tr()),
                ),
              ],
            ),
            IconButton(
              tooltip: 'common_edit'.tr(),
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: TaskPriorityIcon(
                      priority: task.priority,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? colors.onSurface.withValues(alpha: 0.6)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TaskBadgesRow(
                task: task,
                selectedDate: widget.selectedDate,
                isOverdue: isOverdue,
                listContext: TaskTileListContext.detail,
                visibleCalendarCount: linkedCalendarsById.length,
                contextCalendar: contextCalendar,
                linkedEvent: linkedEvent,
                linkedEventMaxTitleLength: 24,
                childTasksBundle: ChildTasksBundle(
                  activeChildren: _activeChildren,
                  completedCount: _completedChildCount,
                  totalCount: _totalChildCount,
                ),
                attachments: _attachments,
                onOpenLinkedEvent: linkedEvent != null
                    ? () => DashboardScreen.openEventDetail(
                          context,
                          event: linkedEvent,
                          selectedDate: widget.selectedDate,
                        )
                    : null,
              ),
              const SizedBox(height: 16),
              if (hasDescription) ...<Widget>[
                Text(
                  description,
                  style: theme.textTheme.bodyLarge,
                ),
              ] else
                Text(
                  'task_description_empty'.tr(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (isOverdue) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  L10n.overdueDays(task.dynamicOverdueDays),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (task.dueDate != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'due_label'.tr(
                    namedArgs: <String, String>{
                      'date': L10n.dateFormat('d MMMM yyyy', context: context)
                          .format(task.dueDate!),
                    },
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ReminderDetailRow(
                reminderAt: task.reminderAt,
              ),
              const SizedBox(height: 8),
              Text(
                'created_label'.tr(
                  namedArgs: <String, String>{
                    'date': L10n.dateFormat(
                      'd MMMM yyyy, HH:mm',
                      context: context,
                    ).format(task.createDate),
                  },
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (!task.isCompleted) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            DashboardScreen.postponeTaskToTomorrow(
                          context,
                          task,
                          widget.selectedDate,
                        ),
                        icon: const Icon(Icons.today_outlined, size: 18),
                        label: Text('task_tomorrow'.tr()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => DashboardScreen.openPostponeTask(
                          context,
                          task,
                          widget.selectedDate,
                        ),
                        icon: const Icon(Icons.event_repeat, size: 18),
                        label: Text('task_postpone'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
              if (linkedEvent != null) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.read<DashboardBloc>().add(
                          UnlinkTaskFromCalendarEvent(task.id),
                        ),
                    icon: const Icon(Icons.link_off, size: 18),
                    label: Text('task_unlink_event'.tr()),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 16),
              TaskDetailChildTasksSection(
                activeChildren: _activeChildren,
                completedChildren: _completedChildren,
                completedCount: _completedChildCount,
                totalCount: _totalChildCount,
                onReorder: _reorderChildren,
                onToggleChildComplete: (Id childId) =>
                    context.read<DashboardBloc>().add(
                      ToggleTaskCompletion(childId),
                    ),
                onDetachChild: (Id childId) => context
                    .read<DashboardBloc>()
                    .add(DetachTaskFromParent(childId)),
                onLinkExistingTask: () => DashboardScreen.openLinkTaskSheet(
                  context,
                  parentTask: task,
                  selectedDate: widget.selectedDate,
                ),
                onOpenChild: (Task child) => DashboardScreen.openTaskDetail(
                  context,
                  taskId: child.id,
                  selectedDate: widget.selectedDate,
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 16),
              TaskAttachmentsSection(
                attachments: _attachments
                    .map(AttachmentRef.fromTask)
                    .toList(growable: false),
                onReorder: _reorderAttachments,
                fileStore:
                    context.read<TaskAttachmentRepository>().fileStore,
                onEditAttachment: (AttachmentRef attachment) {
                  final TaskAttachment source = _attachments.firstWhere(
                    (TaskAttachment a) => a.id == attachment.id,
                  );
                  AttachmentCoordinator.openEditForTask(
                    context,
                    task: task,
                    attachment: source,
                  );
                },
                onDeleteAttachment: (AttachmentRef attachment) {
                  final TaskAttachment source = _attachments.firstWhere(
                    (TaskAttachment a) => a.id == attachment.id,
                  );
                  AttachmentCoordinator.deleteForTaskWithUndo(
                    context,
                    attachment: source,
                  );
                },
                onToggleChecklistItem: (Id attachmentId, int localId) =>
                    context.read<DashboardBloc>().add(
                      ToggleAttachmentChecklistItem(
                        attachmentId: attachmentId,
                        itemLocalId: localId,
                      ),
                    ),
                onAddAttachment: () => AttachmentCoordinator.openAddForTask(
                  context,
                  task: task,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Name prompt when saving a task as a [UiTemplate].
///
/// Owns [TextEditingController] so it is disposed only after the route closes.
class _SaveTaskTemplateDialog extends StatefulWidget {
  const _SaveTaskTemplateDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_SaveTaskTemplateDialog> createState() => _SaveTaskTemplateDialogState();
}

class _SaveTaskTemplateDialogState extends State<_SaveTaskTemplateDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('task_template_dialog_title'.tr()),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'task_template_name_label'.tr(),
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common_cancel'.tr()),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_titleController.text.trim()),
          child: Text('common_save'.tr()),
        ),
      ],
    );
  }
}
