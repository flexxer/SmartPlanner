import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/calendar_integration/domain/event_attachment_snapshot.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';
import 'package:smart_planner/features/notifications/domain/reminder_schedule_time.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_detail_row.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/add_attachment_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Full-screen local calendar event details and linked tasks.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    required this.eventId,
    required this.selectedDate,
    super.key,
  });

  final Id eventId;
  final DateTime selectedDate;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {

  CalendarEvent? _event;
  List<Task> _linkedTasks = <Task>[];
  List<EventAttachment> _attachments = <EventAttachment>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final LocalCalendarEventRepository repository =
        context.read<LocalCalendarEventRepository>();
    final CalendarEvent? event = await repository.getById(widget.eventId);
    if (!mounted) {
      return;
    }
    if (event == null) {
      Navigator.of(context).pop();
      return;
    }
    final List<Task> tasks = await repository.getLinkedTasks(event);
    final EventAttachmentRepository attachmentRepository =
        context.read<EventAttachmentRepository>();
    final List<EventAttachment> attachments =
        await attachmentRepository.getAttachmentsForEvent(widget.eventId);
    setState(() {
      _event = event;
      _linkedTasks = tasks;
      _attachments = attachments;
      _loading = false;
    });
  }

  Future<void> _openAddAttachment() async {
    final CalendarEvent? event = _event;
    if (event == null) {
      return;
    }
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet.forEvent(
        repository: repository,
        eventId: event.id,
      ),
    );
    if (added == true && mounted) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_attachment_added'.tr())),
      );
    }
  }

  Future<void> _openEditAttachment(EventAttachment attachment) async {
    final CalendarEvent? event = _event;
    if (event == null) {
      return;
    }
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet.forEvent(
        repository: repository,
        eventId: event.id,
        attachmentToEdit: attachment,
      ),
    );
    if (saved == true && mounted) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_attachment_updated'.tr())),
      );
    }
  }

  void _deleteAttachmentWithUndo(EventAttachment attachment) {
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final EventAttachment backup = eventAttachmentSnapshot(attachment);
    repository.delete(attachment.id).then((_) async {
      if (mounted) {
        await _load();
      }
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('snackbar_attachment_deleted'.tr()),
        action: SnackBarAction(
          label: 'snackbar_undo'.tr(),
          onPressed: () async {
            await repository.save(backup);
            if (mounted) {
              await _load();
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleChecklistItem(Id attachmentId, int itemLocalId) async {
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final EventAttachment? attachment =
        await repository.getById(attachmentId);
    if (attachment == null ||
        attachment.type != TaskAttachmentType.checklist) {
      return;
    }
    final ChecklistAttachmentPayload checklist =
        TaskAttachmentCodec.checklistRef(AttachmentRef.fromEvent(attachment));
    final int index = checklist.items.indexWhere(
      (ChecklistItemPayload i) => i.localId == itemLocalId,
    );
    if (index < 0) {
      return;
    }
    final List<ChecklistItemPayload> updated =
        List<ChecklistItemPayload>.from(checklist.items);
    final ChecklistItemPayload current = updated[index];
    updated[index] = ChecklistItemPayload(
      localId: current.localId,
      text: current.text,
      isCompleted: !current.isCompleted,
    );
    attachment.payloadJson = TaskAttachmentCodec.encodeMap(
      ChecklistAttachmentPayload(
        title: checklist.title,
        items: updated,
      ).toJson(),
    );
    await repository.update(attachment);
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openEdit() async {
    final CalendarEvent? event = _event;
    if (event == null) {
      return;
    }
    final DashboardState blocState = context.read<DashboardBloc>().state;
    final List<String> selectedCalendarIds = blocState is DashboardLoaded
        ? blocState.selectedCalendarIds
        : const <String>[];
    await DashboardScreen.openEditCalendarEventSheet(
      context,
      event: event,
      selectedCalendarIds: selectedCalendarIds,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final CalendarEvent event = _event!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DashboardState blocState = context.watch<DashboardBloc>().state;
    final Map<String, DeviceCalendarInfo> linkedCalendarsById =
        blocState is DashboardLoaded
            ? blocState.linkedCalendarsById
            : <String, DeviceCalendarInfo>{};
    final DeviceCalendarInfo? calendarInfo =
        linkedCalendarsById[event.calendarId];
    final ({Color background, Color foreground}) calendarColors =
        CalendarContextColors.badgeColorsFor(
      context,
      calendarId: event.calendarId,
      fallbackColorValue: event.colorValue,
    );
    final String calendarLabel = calendarInfo?.name ?? event.calendarId;
    final RecurrenceFrequency? recurrence =
        event.recurrenceRule?.frequency;
    final bool isToday =
        AppDateUtils.isSameCalendarDay(event.start, widget.selectedDate);

    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (DashboardState prev, DashboardState next) =>
          next is DashboardLoaded,
      listener: (BuildContext context, DashboardState state) => _load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('event_title'.tr()),
          actions: <Widget>[
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
                event.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(
                    avatar: Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: calendarColors.foreground,
                    ),
                    label: Text(calendarLabel),
                    backgroundColor: calendarColors.background,
                    labelStyle: TextStyle(color: calendarColors.foreground),
                    side: BorderSide.none,
                  ),
                  if (isToday)
                    Chip(
                      avatar: Icon(
                        Icons.today_outlined,
                        size: 18,
                        color: colors.onPrimaryContainer,
                      ),
                      label: Text('events_on_selected_day'.tr()),
                      backgroundColor: colors.primaryContainer,
                      labelStyle: TextStyle(color: colors.onPrimaryContainer),
                      side: BorderSide.none,
                    ),
                  if (recurrence != null &&
                      recurrence != RecurrenceFrequency.none)
                    Chip(
                      avatar: Icon(
                        Icons.repeat,
                        size: 18,
                        color: colors.onSecondaryContainer,
                      ),
                      label: Text(_recurrenceLabel(recurrence)),
                      backgroundColor: colors.secondaryContainer,
                      labelStyle:
                          TextStyle(color: colors.onSecondaryContainer),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (BuildContext context) {
                  final DateFormat weekdayDate =
                      L10n.dateFormat('EEEE, d MMMM y', context: context);
                  final DateFormat shortDate =
                      L10n.dateFormat('d MMM y', context: context);
                  final DateFormat clock =
                      L10n.dateFormat('HH:mm', context: context);
                  final bool sameCalendarDay =
                      AppDateUtils.isSameCalendarDay(
                    event.start,
                    event.end,
                  );
                  final String dateHeading = sameCalendarDay
                      ? weekdayDate.format(event.start)
                      : '${shortDate.format(event.start)} — '
                          '${shortDate.format(event.end)}';
                  final String timeHeading = sameCalendarDay
                      ? '${clock.format(event.start)} – ${clock.format(event.end)}'
                      : '${clock.format(event.start)} (${shortDate.format(event.start)}) – '
                          '${clock.format(event.end)} (${shortDate.format(event.end)})';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.calendar_today_outlined,
                            color: colors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'event_field_date'.tr(),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateHeading,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.schedule,
                            color: colors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'event_field_time'.tr(),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeHeading,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              ReminderDetailRow(
                minutesBefore: event.reminderMinutesBefore,
                fireAt: ReminderScheduleTime.fireAtForEvent(event),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 16),
              TaskAttachmentsSection(
                attachments: _attachments
                    .map(AttachmentRef.fromEvent)
                    .toList(growable: false),
                fileStore:
                    context.read<EventAttachmentRepository>().fileStore,
                onEditAttachment: (AttachmentRef ref) {
                  final EventAttachment source = _attachments.firstWhere(
                    (EventAttachment a) => a.id == ref.id,
                  );
                  _openEditAttachment(source);
                },
                onDeleteAttachment: (AttachmentRef ref) {
                  final EventAttachment source = _attachments.firstWhere(
                    (EventAttachment a) => a.id == ref.id,
                  );
                  _deleteAttachmentWithUndo(source);
                },
                onToggleChecklistItem: _toggleChecklistItem,
                onAddAttachment: _openAddAttachment,
              ),
              const SizedBox(height: 24),
              Text(
                'events_linked_tasks'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_linkedTasks.isEmpty)
                Text(
                  'events_no_linked_tasks'.tr(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ..._linkedTasks.map(
                  (Task task) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: colors.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) {
                          context.read<DashboardBloc>().add(
                                ToggleTaskCompletion(task.id),
                              );
                        },
                      ),
                      title: Text(
                        task.title,
                        style: task.isCompleted
                            ? theme.textTheme.bodyLarge?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: colors.onSurfaceVariant,
                              )
                            : theme.textTheme.bodyLarge,
                      ),
                      subtitle: task.dueDate != null
                          ? Text(
                              'due_label'.tr(
                                namedArgs: <String, String>{
                                  'date': L10n.dateFormat(
                                    'd MMM yyyy',
                                    context: context,
                                  ).format(task.dueDate!),
                                },
                              ),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => DashboardScreen.openTaskDetail(
                        context,
                        taskId: task.id,
                        selectedDate: widget.selectedDate,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => DashboardScreen.openAttachTaskToEventSheet(
                  context,
                  event: event,
                  selectedDate: widget.selectedDate,
                ),
                icon: const Icon(Icons.link),
                label: Text('task_relation_button'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _recurrenceLabel(RecurrenceFrequency frequency) {
    return L10n.recurrenceLabel(frequency.name);
  }
}
