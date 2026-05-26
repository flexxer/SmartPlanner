import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_badge.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_detail_child_tasks_section.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_child_tasks_section.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/ui_template_factory.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_ui.dart';

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

    final TextEditingController titleController =
        TextEditingController(text: task.title);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('task_template_dialog_title'.tr()),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'task_template_name_label'.tr(),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('common_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('common_save'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      titleController.dispose();
      return;
    }

    final String title = titleController.text.trim();
    titleController.dispose();
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
              Text(
                task.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted
                      ? colors.onSurface.withValues(alpha: 0.6)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _TaskDetailBadges(
                task: task,
                selectedDate: widget.selectedDate,
                isOverdue: isOverdue,
                contextCalendar: contextCalendar,
                linkedEvent: linkedEvent,
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
                attachments: _attachments,
                attachmentRepository:
                    context.read<TaskAttachmentRepository>(),
                onEditAttachment: (TaskAttachment attachment) =>
                    DashboardScreen.openEditAttachmentSheet(
                  context,
                  task: task,
                  attachment: attachment,
                ),
                onDeleteAttachment: (TaskAttachment attachment) =>
                    DashboardScreen.deleteAttachmentWithUndo(
                  context,
                  attachment: attachment,
                ),
                onToggleChecklistItem: (Id attachmentId, int localId) =>
                    context.read<DashboardBloc>().add(
                      ToggleAttachmentChecklistItem(
                        attachmentId: attachmentId,
                        itemLocalId: localId,
                      ),
                    ),
                onAddAttachment: () => DashboardScreen.openAddAttachmentSheet(
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

/// Badges row reused from dashboard tile styling.
class _TaskDetailBadges extends StatelessWidget {
  const _TaskDetailBadges({
    required this.task,
    required this.selectedDate,
    required this.isOverdue,
    this.contextCalendar,
    this.linkedEvent,
    required this.childTasksBundle,
    required this.attachments,
    this.onOpenLinkedEvent,
  });

  final Task task;
  final DateTime selectedDate;
  final bool isOverdue;
  final DeviceCalendarInfo? contextCalendar;
  final CalendarEvent? linkedEvent;
  final ChildTasksBundle childTasksBundle;
  final List<TaskAttachment> attachments;
  final VoidCallback? onOpenLinkedEvent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (_contextCalendarBadge(context) case final Widget calendarBadge)
          calendarBadge,
        TaskBadge(
          label: TaskPriorityUi.label(task.priority),
          backgroundColor:
              TaskPriorityUi.backgroundColor(task.priority, colors),
          foregroundColor:
              TaskPriorityUi.foregroundColor(task.priority, colors),
          icon: Icons.flag_outlined,
        ),
        TaskBadge(
          label: _dueBadgeLabel(context, task, selectedDate),
          backgroundColor: isOverdue
              ? colors.errorContainer
              : colors.primaryContainer,
          foregroundColor: isOverdue
              ? colors.onErrorContainer
              : colors.onPrimaryContainer,
          icon: Icons.event_outlined,
        ),
        if (isOverdue)
          TaskBadge(
            label: L10n.overdueDays(task.dynamicOverdueDays),
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.onErrorContainer,
            icon: Icons.schedule,
          ),
        if (linkedEvent != null)
          TaskBadge(
            label: _linkedEventLabel(linkedEvent!),
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            icon: Icons.event,
            onTap: onOpenLinkedEvent,
          ),
        if (checklistAttachmentProgressBadgeLabel(attachments)
            case final String checklistProgress)
          TaskBadge(
            label: checklistProgress,
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            icon: Icons.fact_check,
          ),
        if (nonChecklistAttachmentCountBadgeLabel(attachments)
            case final String attachCount)
          TaskBadge(
            label: attachCount,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            icon: Icons.attach_file,
          ),
        if (childTaskProgressBadgeLabel(childTasksBundle) case final String progress)
          TaskBadge(
            label: progress,
            backgroundColor: colors.tertiaryContainer,
            foregroundColor: colors.onTertiaryContainer,
            icon: Icons.account_tree,
          ),
      ],
    );
  }

  Widget? _contextCalendarBadge(BuildContext context) {
    final String calendarId = task.calendarId.trim();
    if (calendarId.isEmpty) {
      return null;
    }
    final DeviceCalendarInfo? info = contextCalendar;
    final String label = info?.name ?? calendarId;
    final ({Color background, Color foreground}) badgeColors =
        CalendarContextColors.badgeColorsFor(
      context,
      calendarId: calendarId,
      fallbackColorValue: info?.colorValue,
    );
    return TaskBadge(
      label: label,
      backgroundColor: badgeColors.background,
      foregroundColor: badgeColors.foreground,
      icon: Icons.calendar_month_outlined,
    );
  }

  static String _linkedEventLabel(CalendarEvent event) {
    final String title = event.title.trim();
    if (title.isEmpty) {
      return 'task_event_fallback'.tr();
    }
    if (title.length <= 24) {
      return title;
    }
    return '${title.substring(0, 22)}…';
  }

  static String _dueBadgeLabel(
    BuildContext context,
    Task task,
    DateTime selectedDate,
  ) {
    final DateTime? due = task.dueDate;
    if (due == null) {
      return 'no_due_date'.tr();
    }
    if (AppDateUtils.isSameCalendarDay(due, selectedDate) &&
        AppDateUtils.isToday(selectedDate)) {
      return 'due_today'.tr();
    }
    return L10n.dateFormat('d MMM yyyy', context: context).format(due);
  }
}
