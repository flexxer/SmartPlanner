import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/presentation/attachment_coordinator.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/linked_tasks_completion_list.dart';
import 'package:smart_planner/features/notifications/domain/reminder_schedule_time.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_detail_row.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/event_calendar_sync_service.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/event_sync_calendars_selector.dart';
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

  Future<void> _openEdit() async {
    final CalendarEvent? event = _event;
    if (event == null) {
      return;
    }
    await DashboardScreen.openEditCalendarEventSheet(
      context,
      event: event,
    );
    _load();
  }

  Future<void> _openSync() async {
    final CalendarEvent? event = _event;
    if (event == null) {
      return;
    }

    final Set<String>? selected = await EventSyncCalendarsSheet.show(
      context,
      initialSelected: event.syncedCalendarIds.toSet(),
      linkedCalendarsLoader: LinkedCalendarsLoader(
        calendarService: context.read<DeviceCalendarService>(),
        preferences: context.read<CalendarPreferencesRepository>(),
      ),
    );
    if (selected == null || selected.isEmpty || !mounted) {
      return;
    }

    final LinkedCalendarsLoadResult loadResult = await LinkedCalendarsLoader(
      calendarService: context.read<DeviceCalendarService>(),
      preferences: context.read<CalendarPreferencesRepository>(),
    ).load();
    final List<DeviceCalendarInfo> calendars = loadResult.calendars
        .where(
          (DeviceCalendarInfo c) =>
              selected.contains(c.id) && !c.isReadOnly,
        )
        .toList(growable: false);

    if (calendars.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('event_sync_no_writable'.tr())),
        );
      }
      return;
    }

    try {
      await context.read<EventCalendarSyncService>().syncToCalendars(
            event: event,
            calendars: calendars,
          );
      if (mounted) {
        context.read<DashboardBloc>().add(const LoadDashboardData());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('event_sync_success'.tr())),
        );
        await _load();
      }
    } on CalendarPermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('calendar_settings_permission_needed'.tr())),
        );
      }
    } on CalendarServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
    final String calendarLabel = calendarInfo?.name ??
        (event.isSyncedToDevice
            ? event.calendarId
            : 'event_not_synced'.tr());
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
              tooltip: 'event_sync_title'.tr(),
              onPressed: _openSync,
              icon: const Icon(Icons.sync_outlined),
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
                  AttachmentCoordinator.openEditForEvent(
                    context,
                    eventId: event.id,
                    attachment: source,
                    onChanged: _load,
                  );
                },
                onDeleteAttachment: (AttachmentRef ref) {
                  final EventAttachment source = _attachments.firstWhere(
                    (EventAttachment a) => a.id == ref.id,
                  );
                  AttachmentCoordinator.deleteForEventWithUndo(
                    context,
                    attachment: source,
                    onChanged: _load,
                  );
                },
                onToggleChecklistItem: (Id attachmentId, int itemLocalId) async {
                  await AttachmentCoordinator.toggleEventChecklistItem(
                    repository: context.read<EventAttachmentRepository>(),
                    attachmentId: attachmentId,
                    itemLocalId: itemLocalId,
                  );
                  if (mounted) {
                    await _load();
                  }
                },
                onAddAttachment: () => AttachmentCoordinator.openAddForEvent(
                  context,
                  eventId: event.id,
                  onChanged: _load,
                ),
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
                LinkedTasksCompletionList(
                  tasks: _linkedTasks,
                  onToggleComplete: (Id taskId) {
                    context.read<DashboardBloc>().add(
                          ToggleTaskCompletion(taskId),
                        );
                  },
                  onOpenTask: (Task task) => DashboardScreen.openTaskDetail(
                    context,
                    taskId: task.id,
                    selectedDate: widget.selectedDate,
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
