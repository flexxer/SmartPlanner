import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
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
    setState(() {
      _event = event;
      _linkedTasks = tasks;
      _loading = false;
    });
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
              Row(
                children: <Widget>[
                  Icon(Icons.access_time, color: colors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${L10n.dateFormat('d MMMM yyyy', context: context).format(event.start)} · '
                      '${L10n.dateFormat('HH:mm', context: context).format(event.start)} – '
                      '${L10n.dateFormat('HH:mm', context: context).format(event.end)}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
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
              FilledButton.icon(
                onPressed: () => DashboardScreen.openCreateTaskSheet(
                  context,
                  initialDueDate: widget.selectedDate,
                  linkToEvent: event,
                  selectedCalendarIds: blocState is DashboardLoaded
                      ? blocState.selectedCalendarIds
                      : const <String>[],
                ),
                icon: const Icon(Icons.add),
                label: Text('events_add_task'.tr()),
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
