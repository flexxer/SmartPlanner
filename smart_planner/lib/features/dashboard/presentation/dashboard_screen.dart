import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_grid_screen.dart';
import 'package:smart_planner/features/templates/presentation/pages/templates_page.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_settings_page.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_form_sheet.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_snapshot.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/add_attachment_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/postpone_task_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_expandable_tile.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/event_form_sheet.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_create_fab.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_local_events_section.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_week_date_strip.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/event_detail_screen.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/event_linked_tasks_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/pages/task_detail_screen.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_relation_sheet.dart';

/// Главный экран: события календаря на сегодня и список задач.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = L10n.dateFormat('Hm', context: context);
    final DateFormat dayShortFormat =
        L10n.dateFormat('d MMM', context: context);

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'dashboard_tooltip_time_grid'.tr(),
            onPressed: () => _openCalendarGrid(context),
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'dashboard_tooltip_templates'.tr(),
            onPressed: () => _openTemplates(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'dashboard_tooltip_settings'.tr(),
            onPressed: () => _openCalendarSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'dashboard_tooltip_refresh'.tr(),
            onPressed: () =>
                context.read<DashboardBloc>().add(const LoadDashboardData()),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (BuildContext fabContext) {
          return DashboardCreateFab(
            onCreateTask: () => _openCreateFromFab(fabContext, createEvent: false),
            onCreateEvent: () => _openCreateFromFab(fabContext, createEvent: true),
          );
        },
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (BuildContext context, DashboardState state) {
          return switch (state) {
            DashboardInitial() || DashboardLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DashboardError(:final message) => _ErrorBody(
                message: message,
                onRetry: () => context
                    .read<DashboardBloc>()
                    .add(const LoadDashboardData()),
              ),
            DashboardLoaded(
              :final tasks,
              :final completedTasks,
              :final overdueTasks,
              :final undatedTasks,
              :final calendarEvents,
              :final selectedDate,
              :final selectedCalendarIds,
              :final calendarMessage,
              :final localCalendarEventById,
              :final childTasksByParentId,
              :final attachmentsByTaskId,
              :final dayMarkers,
              :final linkedCalendarsById,
            ) =>
              RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _DateSelectorBar(
                        selectedDate: selectedDate,
                        dayShortFormat: dayShortFormat,
                        dayMarkers: dayMarkers,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DashboardLocalEventsSection(
                        selectedDate: selectedDate,
                        events: calendarEvents,
                        timeFormat: timeFormat,
                        onEventTap: (CalendarEvent event) =>
                            openEventDetail(
                          context,
                          event: event,
                          selectedDate: selectedDate,
                        ),
                        onEventLongPress: (CalendarEvent event) =>
                            openEditCalendarEventSheet(
                          context,
                          event: event,
                          selectedCalendarIds: selectedCalendarIds,
                        ),
                      ),
                    ),
                    if (calendarMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: MaterialBanner(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            content: Text(calendarMessage),
                            leading: const Icon(Icons.info_outline),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => _openCalendarSettings(context),
                                child: Text('common_calendars'.tr()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    if (overdueTasks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _OverdueTasksPanel(
                          overdueTasks: overdueTasks,
                          selectedDate: selectedDate,
                          calendarEvents: calendarEvents,
                          localCalendarEventById: localCalendarEventById,
                          childTasksByParentId: childTasksByParentId,
                          attachmentsByTaskId: attachmentsByTaskId,
                          linkedCalendarsById: linkedCalendarsById,
                        ),
                      ),
                    ..._buildTaskAreaSlivers(
                      context: context,
                      datedTasks: _partitionTasksByCompletion(
                        <Task>[...tasks, ...completedTasks],
                      ),
                      undatedTasks: undatedTasks,
                      selectedDate: selectedDate,
                      calendarEvents: calendarEvents,
                      localCalendarEventById: localCalendarEventById,
                      childTasksByParentId: childTasksByParentId,
                      attachmentsByTaskId: attachmentsByTaskId,
                      linkedCalendarsById: linkedCalendarsById,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }

  static String _dueTasksSectionTitle(
    BuildContext context,
    DateTime selectedDate,
  ) {
    if (AppDateUtils.isToday(selectedDate)) {
      return 'dashboard_due_section_today'.tr();
    }
    return 'dashboard_due_section_on_date'.tr(
      namedArgs: <String, String>{
        'date': L10n.dateFormat('d MMMM', context: context)
            .format(selectedDate),
      },
    );
  }

  static List<Widget> _buildTaskAreaSlivers({
    required BuildContext context,
    required ({List<Task> active, List<Task> completed}) datedTasks,
    required List<Task> undatedTasks,
    required DateTime selectedDate,
    required List<CalendarEvent> calendarEvents,
    required Map<Id, CalendarEvent> localCalendarEventById,
    required Map<Id, ChildTasksBundle> childTasksByParentId,
    required Map<Id, List<TaskAttachment>> attachmentsByTaskId,
    required Map<String, DeviceCalendarInfo> linkedCalendarsById,
  }) {
    final List<Task> activeDated = datedTasks.active;
    final List<Task> completedDated = datedTasks.completed;
    final bool noTasksForDay = activeDated.isEmpty &&
        undatedTasks.isEmpty &&
        completedDated.isEmpty;

    final _TaskTileContext tileContext = _TaskTileContext(
      selectedDate: selectedDate,
      calendarEvents: calendarEvents,
      localCalendarEventById: localCalendarEventById,
      childTasksByParentId: childTasksByParentId,
      attachmentsByTaskId: attachmentsByTaskId,
      linkedCalendarsById: linkedCalendarsById,
    );

    return <Widget>[
      SliverToBoxAdapter(
        child: _DashboardSectionHeader(
          title: _dueTasksSectionTitle(context, selectedDate),
        ),
      ),
      if (activeDated.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => _DashboardTaskTile(
              task: activeDated[index],
              tileContext: tileContext,
            ),
            childCount: activeDated.length,
          ),
        ),
      SliverToBoxAdapter(
        child: _DashboardSectionHeader(
          title: 'backlog_section'.tr(
            namedArgs: <String, String>{'count': '${undatedTasks.length}'},
          ),
          topPadding: activeDated.isEmpty ? 8 : 16,
        ),
      ),
      if (undatedTasks.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => _DashboardTaskTile(
              task: undatedTasks[index],
              tileContext: tileContext,
            ),
            childCount: undatedTasks.length,
          ),
        ),
      if (completedDated.isNotEmpty)
        SliverToBoxAdapter(
          child: _CompletedTasksPanel(
            completedTasks: completedDated,
            selectedDate: selectedDate,
            calendarEvents: calendarEvents,
            localCalendarEventById: localCalendarEventById,
            childTasksByParentId: childTasksByParentId,
            attachmentsByTaskId: attachmentsByTaskId,
            linkedCalendarsById: linkedCalendarsById,
          ),
        ),
      if (noTasksForDay)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _EmptyTasksPlaceholder(selectedDate: selectedDate),
          ),
        ),
    ];
  }

  /// Splits dashboard day tasks into active and completed groups for the list UI.
  static ({List<Task> active, List<Task> completed}) _partitionTasksByCompletion(
    List<Task> tasks,
  ) {
    final List<Task> active = <Task>[];
    final List<Task> completed = <Task>[];
    for (final Task task in tasks) {
      if (task.isCompleted) {
        completed.add(task);
      } else {
        active.add(task);
      }
    }
    return (active: active, completed: completed);
  }

  static Future<void> _openCreateFromFab(
    BuildContext context, {
    required bool createEvent,
  }) async {
    final DashboardState blocState = context.read<DashboardBloc>().state;
    final DateTime selectedDate = blocState is DashboardLoaded
        ? blocState.selectedDate
        : DateTime.now();
    final List<String> selectedCalendarIds = blocState is DashboardLoaded
        ? blocState.selectedCalendarIds
        : const <String>[];

    if (createEvent) {
      await openCreateCalendarEventSheet(
        context,
        selectedDate: selectedDate,
        selectedCalendarIds: selectedCalendarIds,
      );
    } else {
      await openCreateTaskSheet(
        context,
        initialDueDate: selectedDate,
        selectedCalendarIds: selectedCalendarIds,
      );
    }
  }

  static Future<void> openCreateCalendarEventSheet(
    BuildContext context, {
    required DateTime selectedDate,
    List<String> selectedCalendarIds = const <String>[],
  }) async {
    await openEventFormSheet(
      context,
      initialDay: selectedDate,
      selectedCalendarIds: selectedCalendarIds,
    );
  }

  static Future<void> openEventFormSheet(
    BuildContext context, {
    CalendarEvent? eventToEdit,
    DateTime? initialDay,
    String? initialTitle,
    DateTime? initialStart,
    DateTime? initialEnd,
    List<String> selectedCalendarIds = const <String>[],
  }) async {
    final DashboardBloc dashboardBloc = context.read<DashboardBloc>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => EventFormSheet(
        repository: sheetContext.read<LocalCalendarEventRepository>(),
        eventToEdit: eventToEdit,
        initialDay: initialDay,
        initialTitle: initialTitle,
        initialStart: initialStart,
        initialEnd: initialEnd,
        selectedCalendarIds: selectedCalendarIds,
        dashboardBloc: dashboardBloc,
        linkedCalendarsLoader: LinkedCalendarsLoader(
          calendarService: sheetContext.read<DeviceCalendarService>(),
          preferences: sheetContext.read<CalendarPreferencesRepository>(),
        ),
      ),
    );
    if (!context.mounted || saved != true) {
      return;
    }
    if (eventToEdit == null) {
      dashboardBloc.add(const LoadDashboardData());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_event_created'.tr())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_event_updated'.tr())),
      );
    }
  }

  static Future<void> openCreateTaskSheet(
    BuildContext context, {
    DateTime? initialDueDate,
    CalendarEvent? linkToEvent,
    List<String> selectedCalendarIds = const <String>[],
  }) async {
    await openTaskFormSheet(
      context,
      initialDueDate: initialDueDate,
      linkToEvent: linkToEvent,
      selectedCalendarIds: selectedCalendarIds,
    );
  }

  static Future<void> openTaskFormSheet(
    BuildContext context, {
    Task? taskToEdit,
    DateTime? initialDueDate,
    String? initialTitle,
    TaskPriority? initialPriority,
    CalendarEvent? linkToEvent,
    List<String> selectedCalendarIds = const <String>[],
    UiTemplate? templateToApply,
    Id? initialParentTaskId,
  }) async {
    final DashboardBloc dashboardBloc = context.read<DashboardBloc>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => TaskFormSheet(
        repository: sheetContext.read<TodoRepository>(),
        taskToEdit: taskToEdit,
        dashboardBloc: taskToEdit != null ? dashboardBloc : null,
        localCalendarRepository:
            sheetContext.read<LocalCalendarEventRepository>(),
        initialDueDate: initialDueDate,
        initialTitle: initialTitle,
        initialPriority: initialPriority,
        initialLinkedEventId: linkToEvent?.id,
        initialCalendarId: linkToEvent?.calendarId,
        linkedEventTitle: linkToEvent?.title,
        selectedCalendarIds: selectedCalendarIds,
        templateToApply: templateToApply,
        initialParentTaskId: initialParentTaskId,
        attachmentRepository: sheetContext.read<TaskAttachmentRepository>(),
      ),
    );
    if (!context.mounted || saved != true) {
      return;
    }
    if (taskToEdit == null) {
      dashboardBloc.add(const LoadDashboardData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_task_updated'.tr())),
      );
    }
  }

  static Future<void> openLinkCalendarEventSheet(
    BuildContext context, {
    required Task task,
    required List<CalendarEvent> dayEvents,
  }) async {
    await _showTaskRelationSheet(
      context,
      target: TaskRelationPickEventTarget(
        task: task,
        dayEvents: dayEvents,
      ),
    );
  }

  static Future<void> openAttachTaskToParentSheet(
    BuildContext context, {
    required Task parentTask,
    required DateTime selectedDate,
  }) async {
    await _showTaskRelationSheet(
      context,
      target: TaskRelationParentTarget(
        parentTaskId: parentTask.id,
        title: parentTask.title,
        selectedDate: selectedDate,
      ),
    );
  }

  static Future<void> openAttachTaskToEventSheet(
    BuildContext context, {
    required CalendarEvent event,
    required DateTime selectedDate,
  }) async {
    await _showTaskRelationSheet(
      context,
      target: TaskRelationEventTarget(
        event: event,
        selectedDate: selectedDate,
      ),
    );
  }

  static Future<void> _showTaskRelationSheet(
    BuildContext context, {
    required TaskRelationTarget target,
  }) async {
    final Object? result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => TaskRelationSheet(target: target),
    );
    if (!context.mounted || result == null) {
      return;
    }
    await _handleTaskRelationResult(
      context,
      target: target,
      result: result,
    );
  }

  static Future<void> _handleTaskRelationResult(
    BuildContext context, {
    required TaskRelationTarget target,
    required Object result,
  }) async {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final DashboardState state = bloc.state;
    final List<String> selectedCalendarIds = state is DashboardLoaded
        ? state.selectedCalendarIds
        : const <String>[];

    switch (result) {
      case TaskRelationLinkedExistingTask(:final Id taskId):
        await _applyExistingTaskRelation(
          context,
          target: target,
          taskId: taskId,
        );
      case TaskRelationPickedEvent(:final CalendarEvent event):
        if (target case TaskRelationPickEventTarget(:final Task task)) {
          bloc.add(
            LinkTaskToCalendarEvent(taskId: task.id, eventId: event.id),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'snackbar_task_linked_event'.tr(
                    namedArgs: <String, String>{'title': event.title},
                  ),
                ),
              ),
            );
          }
        }
      case TaskRelationCreateTaskRequested(:final UiTemplate? template):
        await _openCreateTaskFromRelation(
          context,
          target: target,
          template: template,
          selectedCalendarIds: selectedCalendarIds,
        );
    }
  }

  static Future<void> _applyExistingTaskRelation(
    BuildContext context, {
    required TaskRelationTarget target,
    required Id taskId,
  }) async {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final TodoRepository repository = context.read<TodoRepository>();

    switch (target) {
      case TaskRelationParentTarget(:final Id parentTaskId):
        final bool ok = await repository.attachTaskToParent(
          childTaskId: taskId,
          parentTaskId: parentTaskId,
        );
        if (!context.mounted) {
          return;
        }
        if (ok) {
          bloc.add(const LoadDashboardData());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('snackbar_task_linked_child'.tr())),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('link_task_failed'.tr())),
          );
        }
      case TaskRelationEventTarget(:final CalendarEvent event):
        bloc.add(
          LinkTaskToCalendarEvent(taskId: taskId, eventId: event.id),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'snackbar_task_linked_event'.tr(
                  namedArgs: <String, String>{'title': event.title},
                ),
              ),
            ),
          );
        }
      case TaskRelationPickEventTarget():
        break;
    }
  }

  static Future<void> _openCreateTaskFromRelation(
    BuildContext context, {
    required TaskRelationTarget target,
    required UiTemplate? template,
    required List<String> selectedCalendarIds,
  }) async {
    switch (target) {
      case TaskRelationParentTarget(
          :final Id parentTaskId,
          :final DateTime selectedDate,
        ):
        await openTaskFormSheet(
          context,
          initialDueDate: selectedDate,
          templateToApply: template,
          selectedCalendarIds: selectedCalendarIds,
          initialParentTaskId: parentTaskId,
        );
      case TaskRelationEventTarget(
          :final CalendarEvent event,
          :final DateTime selectedDate,
        ):
        await openTaskFormSheet(
          context,
          initialDueDate: selectedDate,
          linkToEvent: event,
          templateToApply: template,
          selectedCalendarIds: selectedCalendarIds,
        );
      case TaskRelationPickEventTarget():
        return;
    }
  }

  static Future<void> openEditCalendarEventSheet(
    BuildContext context, {
    required CalendarEvent event,
    List<String> selectedCalendarIds = const <String>[],
  }) async {
    await openEventFormSheet(
      context,
      eventToEdit: event,
      selectedCalendarIds: selectedCalendarIds,
    );
  }

  static Future<void> openEditTaskSheet(
    BuildContext context, {
    required Task task,
    List<String> selectedCalendarIds = const <String>[],
  }) async {
    await openTaskFormSheet(
      context,
      taskToEdit: task,
      selectedCalendarIds: selectedCalendarIds,
    );
  }

  static Future<void> openTaskDetail(
    BuildContext context, {
    required Id taskId,
    required DateTime selectedDate,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<DashboardBloc>.value(
          value: context.read<DashboardBloc>(),
          child: TaskDetailScreen(
            taskId: taskId,
            selectedDate: selectedDate,
          ),
        ),
      ),
    );
  }

  static Future<void> openEventDetail(
    BuildContext context, {
    required CalendarEvent event,
    required DateTime selectedDate,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<DashboardBloc>.value(
          value: context.read<DashboardBloc>(),
          child: EventDetailScreen(
            eventId: event.id,
            selectedDate: selectedDate,
          ),
        ),
      ),
    );
  }

  static Future<void> openEventLinkedTasks(
    BuildContext context, {
    required CalendarEvent event,
    required DateTime selectedDate,
  }) async {
    final LocalCalendarEventRepository localRepo =
        context.read<LocalCalendarEventRepository>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => EventLinkedTasksSheet(
        event: event,
        localCalendarRepository: localRepo,
        onAddTask: () {
          Navigator.of(sheetContext).pop();
          openAttachTaskToEventSheet(
            context,
            event: event,
            selectedDate: selectedDate,
          );
        },
        onToggleTaskCompletion: (Id taskId) {
          context.read<DashboardBloc>().add(ToggleTaskCompletion(taskId));
        },
        onTaskSelected: (Id taskId) {
          Navigator.of(sheetContext).pop();
          openTaskDetail(
            context,
            taskId: taskId,
            selectedDate: selectedDate,
          );
        },
      ),
    );
  }

  static Future<void> _openTemplates(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<DashboardBloc>.value(
          value: context.read<DashboardBloc>(),
          child: const TemplatesPage(),
        ),
      ),
    );
  }

  static Future<void> _openCalendarGrid(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<DashboardBloc>.value(
          value: context.read<DashboardBloc>(),
          child: const CalendarGridScreen(),
        ),
      ),
    );
  }

  static Future<void> _openCalendarSettings(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardBloc>(),
          child: const CalendarSettingsPage(),
        ),
      ),
    );
  }

  static Future<void> _onRefresh(BuildContext context) async {
    context.read<DashboardBloc>().add(const LoadDashboardData());
    await context.read<DashboardBloc>().stream.firstWhere(
          (DashboardState s) => s is! DashboardLoading,
        );
  }

  static void postponeTaskToTomorrow(
    BuildContext context,
    Task task,
    DateTime selectedDate,
  ) {
    final DateTime tomorrow = AppDateUtils.startOfDay(selectedDate).add(
      const Duration(days: 1),
    );
    context.read<DashboardBloc>().add(PostponeTaskToNextDay(task.id));
    _showPostponeSnackBar(context, tomorrow);
  }

  static Future<void> openAddAttachmentSheet(
    BuildContext context, {
    required Task task,
  }) async {
    final TaskAttachmentRepository repository =
        context.read<TaskAttachmentRepository>();
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet(
        repository: repository,
        taskId: task.id,
      ),
    );
    if (added == true && context.mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_attachment_added'.tr())),
      );
    }
  }

  static Future<void> openEditAttachmentSheet(
    BuildContext context, {
    required Task task,
    required TaskAttachment attachment,
  }) async {
    final DashboardBloc dashboardBloc = context.read<DashboardBloc>();
    final TaskAttachmentRepository repository =
        context.read<TaskAttachmentRepository>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet(
        repository: repository,
        taskId: task.id,
        attachmentToEdit: attachment,
        dashboardBloc: dashboardBloc,
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('snackbar_attachment_updated'.tr())),
      );
    }
  }

  static void deleteAttachmentWithUndo(
    BuildContext context, {
    required TaskAttachment attachment,
  }) {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final TaskAttachment backup = taskAttachmentSnapshot(attachment);
    bloc.add(DeleteTaskAttachment(attachment.id));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('snackbar_attachment_deleted'.tr()),
        action: SnackBarAction(
          label: 'snackbar_undo'.tr(),
          onPressed: () => bloc.add(RestoreTaskAttachment(backup)),
        ),
      ),
    );
  }

  static Future<void> openLinkTaskSheet(
    BuildContext context, {
    required Task parentTask,
    required DateTime selectedDate,
  }) async {
    await openAttachTaskToParentSheet(
      context,
      parentTask: parentTask,
      selectedDate: selectedDate,
    );
  }

  static Future<void> openPostponeTask(
    BuildContext context,
    Task task,
    DateTime selectedDate,
  ) async {
    final DateTime? newDueDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => PostponeTaskSheet(
        task: task,
        referenceDate: selectedDate,
      ),
    );
    if (newDueDate == null || !context.mounted) {
      return;
    }

    context.read<DashboardBloc>().add(
          PostponeTask(taskId: task.id, newDueDate: newDueDate),
        );
    _showPostponeSnackBar(context, newDueDate);
  }

  static void _showPostponeSnackBar(BuildContext context, DateTime newDueDate) {
    final String dateLabel =
        L10n.dateFormat('d MMM yyyy', context: context).format(newDueDate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'snackbar_due_postponed'.tr(
            namedArgs: <String, String>{'date': dateLabel},
          ),
        ),
      ),
    );
  }
}

class _DateSelectorBar extends StatelessWidget {
  const _DateSelectorBar({
    required this.selectedDate,
    required this.dayShortFormat,
    required this.dayMarkers,
  });

  final DateTime selectedDate;
  final DateFormat dayShortFormat;
  final Map<int, DayActivityMarker> dayMarkers;

  @override
  Widget build(BuildContext context) {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final bool isToday = AppDateUtils.isToday(selectedDate);
    final String label = isToday
        ? 'common_today'.tr()
        : dayShortFormat.format(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'dashboard_prev_day'.tr(),
                onPressed: () => bloc.add(
                  SelectDashboardDate(
                    selectedDate.subtract(const Duration(days: 1)),
                  ),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickDate(context, bloc, selectedDate),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'dashboard_next_day'.tr(),
                onPressed: () => bloc.add(
                  SelectDashboardDate(
                    selectedDate.add(const Duration(days: 1)),
                  ),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
              if (!isToday)
                TextButton(
                  onPressed: () => bloc.add(
                    SelectDashboardDate(DateTime.now()),
                  ),
                  child: Text('common_today'.tr()),
                ),
            ],
          ),
          const SizedBox(height: 4),
          DashboardWeekDateStrip(
            selectedDate: selectedDate,
            dayMarkers: dayMarkers,
            onDateSelected: (DateTime date) =>
                bloc.add(SelectDashboardDate(date)),
          ),
        ],
      ),
    );
  }

  static Future<void> _pickDate(
    BuildContext context,
    DashboardBloc bloc,
    DateTime current,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: context.locale,
    );
    if (picked != null && context.mounted) {
      bloc.add(SelectDashboardDate(picked));
    }
  }
}

class _OverdueTasksPanel extends StatelessWidget {
  const _OverdueTasksPanel({
    required this.overdueTasks,
    required this.selectedDate,
    required this.calendarEvents,
    required this.localCalendarEventById,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
    required this.linkedCalendarsById,
  });

  final List<Task> overdueTasks;
  final DateTime selectedDate;
  final List<CalendarEvent> calendarEvents;
  final Map<Id, CalendarEvent> localCalendarEventById;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;
  final Map<String, DeviceCalendarInfo> linkedCalendarsById;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int count = overdueTasks.length;
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.error,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(
            dividerColor: colors.surfaceContainerHighest,
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'overdue_section'.tr(namedArgs: <String, String>{
                'count': '$count',
              }),
              style: titleStyle,
            ),
            iconColor: colors.error,
            collapsedIconColor: colors.error,
            children: <Widget>[
              for (final Task task in overdueTasks)
                _DashboardTaskTile(
                  task: task,
                  tileContext: _TaskTileContext(
                    selectedDate: selectedDate,
                    calendarEvents: calendarEvents,
                    localCalendarEventById: localCalendarEventById,
                    childTasksByParentId: childTasksByParentId,
                    attachmentsByTaskId: attachmentsByTaskId,
                    linkedCalendarsById: linkedCalendarsById,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTaskTile extends StatelessWidget {
  const _DashboardTaskTile({
    required this.task,
    required this.tileContext,
    this.dimAsCompleted = false,
  });

  final Task task;
  final _TaskTileContext tileContext;
  final bool dimAsCompleted;

  @override
  Widget build(BuildContext context) {
    final ChildTasksBundle childBundle =
        tileContext.childTasksByParentId[task.id] ??
        const ChildTasksBundle(
          activeChildren: <Task>[],
          completedCount: 0,
          totalCount: 0,
        );
    final List<TaskAttachment> attachments =
        tileContext.attachmentsByTaskId[task.id] ?? const <TaskAttachment>[];

    final CalendarEvent? linkedEvent =
        tileContext.localCalendarEventById[task.linkedEventId];

    final Widget tile = TaskExpandableTile(
      task: task,
      selectedDate: tileContext.selectedDate,
      contextCalendar: tileContext.linkedCalendarsById[task.calendarId],
      childTasksBundle: childBundle,
      attachments: attachments,
      linkedEvent: linkedEvent,
      onOpenDetail: () => DashboardScreen.openTaskDetail(
        context,
        taskId: task.id,
        selectedDate: tileContext.selectedDate,
      ),
      onLinkToCalendarEvent: () => DashboardScreen.openLinkCalendarEventSheet(
        context,
        task: task,
        dayEvents: tileContext.calendarEvents,
      ),
      onOpenLinkedEvent: linkedEvent != null
          ? () => DashboardScreen.openEventDetail(
                context,
                event: linkedEvent,
                selectedDate: tileContext.selectedDate,
              )
          : null,
      onToggleComplete: () => context.read<DashboardBloc>().add(
            ToggleTaskCompletion(task.id),
          ),
    );

    if (!dimAsCompleted) {
      return tile;
    }

    return Opacity(opacity: 0.5, child: tile);
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({
    required this.title,
    this.topPadding = 16,
  });

  final String title;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyTasksPlaceholder extends StatelessWidget {
  const _EmptyTasksPlaceholder({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final String hint = AppDateUtils.isToday(selectedDate)
        ? 'dashboard_empty_today'.tr()
        : 'dashboard_empty_day'.tr();
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Text(
        '$hint\n${'dashboard_empty_local_note'.tr()}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _TaskTileContext {
  const _TaskTileContext({
    required this.selectedDate,
    required this.calendarEvents,
    required this.localCalendarEventById,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
    required this.linkedCalendarsById,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> calendarEvents;
  final Map<Id, CalendarEvent> localCalendarEventById;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;
  final Map<String, DeviceCalendarInfo> linkedCalendarsById;
}

class _CompletedTasksPanel extends StatelessWidget {
  const _CompletedTasksPanel({
    required this.completedTasks,
    required this.selectedDate,
    required this.calendarEvents,
    required this.localCalendarEventById,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
    required this.linkedCalendarsById,
  });

  final List<Task> completedTasks;
  final DateTime selectedDate;
  final List<CalendarEvent> calendarEvents;
  final Map<Id, CalendarEvent> localCalendarEventById;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;
  final Map<String, DeviceCalendarInfo> linkedCalendarsById;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int count = completedTasks.length;
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(
            dividerColor: colors.surfaceContainerHighest,
          ),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'completed_section'.tr(namedArgs: <String, String>{
                'count': '$count',
              }),
              style: titleStyle,
            ),
            iconColor: colors.onSurfaceVariant,
            collapsedIconColor: colors.onSurfaceVariant,
            children: <Widget>[
              for (final Task task in completedTasks)
                _DashboardTaskTile(
                  task: task,
                  tileContext: _TaskTileContext(
                    selectedDate: selectedDate,
                    calendarEvents: calendarEvents,
                    localCalendarEventById: localCalendarEventById,
                    childTasksByParentId: childTasksByParentId,
                    attachmentsByTaskId: attachmentsByTaskId,
                    linkedCalendarsById: linkedCalendarsById,
                  ),
                  dimAsCompleted: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text('common_retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

