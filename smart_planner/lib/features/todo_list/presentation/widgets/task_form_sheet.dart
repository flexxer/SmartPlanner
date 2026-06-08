import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/presentation/widgets/confirm_delete_record.dart';
import 'package:smart_planner/core/presentation/widgets/form_sheet_scaffold.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/linked_calendars_field.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/task_event_link_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/record_delete_coordinator.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/templates/domain/ui_template_applicator.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/notifications/domain/task_reminder_defaults.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_at_field.dart';

/// Bottom sheet to create or edit a [Task].
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    required this.repository,
    this.taskToEdit,
    this.initialDueDate,
    this.initialLinkedEventId,
    this.initialCalendarId,
    this.linkedEventTitle,
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
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.none;
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
      _recurrenceFrequency =
          existing.recurrenceRule?.frequency ?? RecurrenceFrequency.none;
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
    await context.read<ReminderSyncService>().syncTask(task);
  }

  Future<void> _deleteTask() async {
    final Task? task = widget.taskToEdit;
    final DashboardBloc? bloc = widget.dashboardBloc;
    if (task == null || bloc == null) {
      return;
    }

    final bool confirmed = await confirmDeleteRecord(context);
    if (!confirmed || !mounted) {
      return;
    }

    await RecordDeleteCoordinator.deleteTask(
      context,
      task: task,
      bloc: bloc,
      onDeleted: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
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

  RecurrenceRule? _buildRecurrenceRule() {
    if (_dueDate == null || _recurrenceFrequency == RecurrenceFrequency.none) {
      return null;
    }
    return RecurrenceRule(frequency: _recurrenceFrequency);
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
      ..reminderAt = _reminderAt
      ..recurrenceRule = _buildRecurrenceRule();
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
      reminderAt: _reminderAt,
    )..recurrenceRule = _buildRecurrenceRule();
    final Id taskId = await widget.repository.saveTask(task);
    task.id = taskId;
    final TaskEventLinkService linkService =
        context.read<TaskEventLinkService>();
    await _syncReminderForTask(task);
    await linkService.applyPostCreateRelations(
      taskId: taskId,
      linkedEventId: widget.initialLinkedEventId,
      parentTaskId: widget.initialParentTaskId,
    );

    final UiTemplate? template = widget.templateToApply;
    final TaskAttachmentRepository? attachmentRepo =
        widget.attachmentRepository;
    if (template != null && attachmentRepo != null) {
      await UiTemplateApplicator(
        attachmentRepository: attachmentRepo,
      ).applyToTask(taskId: taskId, template: template);
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
    final bool isEditing = widget.isEditing;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FormSheetScaffold(
      title: isEditing ? 'task_edit'.tr() : 'task_new'.tr(),
      onDelete: isEditing ? _deleteTask : null,
      deleteEnabled: !_saving,
      headerChildren: <Widget>[
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
              backgroundColor: colors.primaryContainer,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.24)),
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
                      color: colors.primary,
                    ),
              ),
              backgroundColor: colors.primaryContainer,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.24)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ],
      children: <Widget>[
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
              LinkedCalendarsField(
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
              if (_dueDate != null) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _recurrenceFrequency,
                  decoration: InputDecoration(
                    labelText: 'task_field_recurrence'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: <RecurrenceFrequency>[
                    RecurrenceFrequency.none,
                    RecurrenceFrequency.daily,
                    RecurrenceFrequency.weekly,
                  ]
                      .map(
                        (RecurrenceFrequency frequency) =>
                            DropdownMenuItem<RecurrenceFrequency>(
                          value: frequency,
                          child: Text(L10n.recurrenceLabel(frequency.name)),
                        ),
                      )
                      .toList(),
                  onChanged: (RecurrenceFrequency? value) {
                    if (value != null) {
                      setState(() => _recurrenceFrequency = value);
                    }
                  },
                ),
              ],
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
              FormSheetSaveButton(
                label: isEditing
                    ? 'task_save_changes'.tr()
                    : 'common_save'.tr(),
                enabled: !_saving,
                onPressed: _save,
              ),
      ],
    );
  }
}
