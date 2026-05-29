import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/templates/domain/ui_template_applicator.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/notifications/domain/task_reminder_defaults.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_at_field.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_linked_calendars_field.dart';

/// Bottom sheet to create or edit a [Task].
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    required this.repository,
    this.taskToEdit,
    this.initialDueDate,
    this.initialLinkedEventId,
    this.initialCalendarId,
    this.linkedEventTitle,
    this.localCalendarRepository,
    this.selectedCalendarIds,
    this.dashboardBloc,
    this.templateToApply,
    this.attachmentRepository,
    this.initialTitle,
    this.initialPriority,
    this.initialParentTaskId,
    super.key,
  });

  final TodoRepository repository;

  /// When set, the sheet opens in edit mode with fields prefilled.
  final Task? taskToEdit;

  final LocalCalendarEventRepository? localCalendarRepository;

  /// Used when creating a task (ignored if [taskToEdit] is set).
  final DateTime? initialDueDate;

  /// Pre-filled link to a local calendar event (create mode only).
  final int? initialLinkedEventId;

  final String? initialCalendarId;
  final String? linkedEventTitle;
  final List<String>? selectedCalendarIds;

  /// When set, edit saves dispatch [UpdateTask] on this bloc.
  final DashboardBloc? dashboardBloc;

  /// Prefills fields and creates checklist/embedded attachments after save.
  final UiTemplate? templateToApply;

  final TaskAttachmentRepository? attachmentRepository;

  /// Prefilled title when creating (e.g. from a deep link).
  final String? initialTitle;

  /// Prefilled priority when creating (e.g. from a deep link).
  final TaskPriority? initialPriority;

  /// After save, attach the new task under this parent ([Task.parentTaskId]).
  final Id? initialParentTaskId;

  bool get isEditing => taskToEdit != null;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late TaskPriority _priority;
  String? _selectedCalendarId;
  DateTime? _reminderAt;
  bool _reminderLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Task? existing = widget.taskToEdit;
    if (existing != null) {
      _titleController = TextEditingController(text: existing.title);
      _descriptionController =
          TextEditingController(text: existing.description ?? '');
      _dueDate = existing.dueDate;
      _priority = existing.priority;
      final String calendarId = existing.calendarId;
      _selectedCalendarId = calendarId.isEmpty ? null : calendarId;
      _reminderAt = existing.reminderAt;
      _reminderLoaded = true;
    } else {
      final UiTemplate? template = widget.templateToApply;
      final String titleText = widget.initialTitle?.isNotEmpty == true
          ? widget.initialTitle!
          : (template?.title ?? '');
      _titleController = TextEditingController(text: titleText);
      _descriptionController = TextEditingController(
        text: template?.templateDescription ?? '',
      );
      _dueDate = widget.initialDueDate;
      _priority = widget.initialPriority ?? TaskPriority.medium;
      final String? initialId = widget.initialCalendarId;
      if (initialId != null && initialId.isNotEmpty) {
        _selectedCalendarId = initialId;
      }
      _loadDefaultReminder();
    }
  }

  Future<void> _loadDefaultReminder() async {
    final DateTime at = await TaskReminderDefaults.defaultReminderAt(
      dueDate: _dueDate,
    );
    if (mounted) {
      setState(() {
        _reminderAt = at;
        _reminderLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: context.locale,
    );
    if (picked != null) {
      setState(() {
        _dueDate = AppDateUtils.startOfDay(picked);
      });
      if (_reminderAt == null) {
        await _loadDefaultReminder();
      }
    }
  }

  Future<void> _syncReminderForTask(Task task) async {
    try {
      await ItemReminderScheduler().syncTask(task);
    } on Object {
      // Scheduling is best-effort; save already succeeded.
    }
  }

  Future<bool> _confirmDeleteRecord() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text('delete_dialog_title'.tr()),
          content: Text('delete_dialog_body'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('common_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: Text('common_delete'.tr()),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _deleteTask() async {
    final Task? task = widget.taskToEdit;
    final DashboardBloc? bloc = widget.dashboardBloc;
    if (task == null || bloc == null) {
      return;
    }

    final bool confirmed = await _confirmDeleteRecord();
    if (!confirmed || !mounted) {
      return;
    }

    bloc.add(DeleteTask(task.id));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('task_enter_title'.tr())),
      );
      return;
    }

    final String? calendarId = _selectedCalendarId;
    if (calendarId == null || calendarId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('task_select_calendar'.tr())),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.isEditing) {
        await _saveEdit(title: title, calendarId: calendarId);
      } else {
        await _saveCreate(title: title, calendarId: calendarId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'common_error_with_details'.tr(namedArgs: <String, String>{
                'details': '$e',
              }),
            ),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveEdit({
    required String title,
    required String calendarId,
  }) async {
    final Task task = widget.taskToEdit!
      ..title = title
      ..description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim()
      ..dueDate = _dueDate
      ..priority = _priority
      ..calendarId = calendarId
      ..reminderAt = _reminderAt;
    task.markUpdated();

    final DashboardBloc? bloc = widget.dashboardBloc;
    if (bloc != null) {
      bloc.add(UpdateTask(task));
    } else {
      await widget.repository.updateTask(task);
      await _syncReminderForTask(task);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveCreate({
    required String title,
    required String calendarId,
  }) async {
    final Task task = Task.create(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      calendarId: calendarId,
      linkedEventId: widget.initialLinkedEventId,
      reminderAt: _reminderAt,
    );
    final Id taskId = await widget.repository.saveTask(task);
    task.id = taskId;
    await _syncReminderForTask(task);
    final Id? linkedEventId = widget.initialLinkedEventId;
    final LocalCalendarEventRepository? localRepo =
        widget.localCalendarRepository;
    if (linkedEventId != null && localRepo != null) {
      await localRepo.linkTask(eventId: linkedEventId, taskId: taskId);
    }

    final UiTemplate? template = widget.templateToApply;
    final TaskAttachmentRepository? attachmentRepo =
        widget.attachmentRepository;
    if (template != null && attachmentRepo != null) {
      await UiTemplateApplicator(
        attachmentRepository: attachmentRepo,
      ).applyToTask(taskId: taskId, template: template);
    }

    final Id? parentTaskId = widget.initialParentTaskId;
    if (parentTaskId != null) {
      await widget.repository.attachTaskToParent(
        childTaskId: taskId,
        parentTaskId: parentTaskId,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _formatDate(DateTime date) {
    return L10n.dateFormat('dd.MM.yyyy', context: context).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final bool isEditing = widget.isEditing;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      isEditing ? 'task_edit'.tr() : 'task_new'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      tooltip: 'task_delete_tooltip'.tr(),
                      onPressed: _saving ? null : _deleteTask,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colors.error,
                      ),
                    ),
                ],
              ),
              if (!isEditing && widget.templateToApply != null) ...<Widget>[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.layers_outlined, size: 18),
                    label: Text(
                      'task_template_applied'.tr(
                        namedArgs: <String, String>{
                          'title': widget.templateToApply!.title,
                        },
                      ),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    backgroundColor: colors.surfaceContainerHighest,
                    side: BorderSide.none,
                  ),
                ),
              ],
              if (!isEditing &&
                  widget.initialLinkedEventId != null &&
                  widget.linkedEventTitle != null &&
                  widget.linkedEventTitle!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      'task_linked_meeting_label'.tr(
                        namedArgs: <String, String>{
                          'title': widget.linkedEventTitle!.trim(),
                        },
                      ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'task_field_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'task_field_description_optional'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: isEditing ? 3 : 2,
              ),
              const SizedBox(height: 12),
              TaskLinkedCalendarsField(
                selectedCalendarId: _selectedCalendarId,
                selectedCalendarIds: widget.selectedCalendarIds,
                onCalendarSelected: (DeviceCalendarInfo calendar) {
                  setState(() => _selectedCalendarId = calendar.id);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: InputDecoration(
                  labelText: 'field_priority'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: TaskPriority.values
                    .map(
                      (TaskPriority p) => DropdownMenuItem<TaskPriority>(
                        value: p,
                        child: Text(L10n.priorityLabel(p)),
                      ),
                    )
                    .toList(),
                onChanged: (TaskPriority? value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.event),
                      label: Text(
                        _dueDate == null
                            ? 'task_no_due_date'.tr()
                            : 'task_due_date_label'.tr(
                                namedArgs: <String, String>{
                                  'date': _formatDate(_dueDate!),
                                },
                              ),
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...<Widget>[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'task_clear_due_tooltip'.tr(),
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              if (_reminderLoaded) ...<Widget>[
                const SizedBox(height: 12),
                ReminderAtField(
                  reminderAt: _reminderAt,
                  onChanged: (DateTime? value) {
                    setState(() => _reminderAt = value);
                  },
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditing
                            ? 'task_save_changes'.tr()
                            : 'common_save'.tr(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
