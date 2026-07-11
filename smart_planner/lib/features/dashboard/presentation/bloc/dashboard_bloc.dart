import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/app_initializer.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_event_write_service.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/data/task_event_link_service.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_calendar_mutations.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_data_loader.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_dependencies.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_task_mutations.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_load_models.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc_helpers.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

/// Coordinates dashboard loading and dispatches mutations to dedicated helpers.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required TodoRepository todoRepository,
    required CalendarService calendarService,
    CalendarPreferencesRepository? calendarPreferences,
    TaskAttachmentRepository? attachmentRepository,
    DashboardDayMarkersRepository? dayMarkersRepository,
    LocalCalendarEventRepository? localCalendarEventRepository,
    DayStatusNotificationController? dayStatusNotifications,
    DayStatusHomeWidgetService? dayStatusHomeWidget,
    ReminderSyncService? reminderSync,
    TaskEventLinkService? taskEventLinkService,
    EventAttachmentRepository? eventAttachmentRepository,
  })  : _selectedDate = AppDateUtils.startOfDay(DateTime.now()),
        _dayStatusNotifications = dayStatusNotifications,
        _dayStatusHomeWidget = dayStatusHomeWidget,
        super(const DashboardInitial()) {
    final LocalCalendarEventRepository localEvents =
        localCalendarEventRepository ?? LocalCalendarEventRepository();
    final DashboardDependencies deps = DashboardDependencies(
      todoRepository: todoRepository,
      calendarService: calendarService,
      calendarPreferences:
          calendarPreferences ?? CalendarPreferencesRepository(),
      localCalendarEvents: localEvents,
      dayMarkersRepository: dayMarkersRepository ??
          DashboardDayMarkersRepository(
            todoRepository: todoRepository,
            localCalendarEventRepository: localEvents,
          ),
      attachmentRepository:
          attachmentRepository ?? TaskAttachmentRepository(),
      eventAttachments:
          eventAttachmentRepository ?? EventAttachmentRepository(),
      taskEventLinks: taskEventLinkService ??
          TaskEventLinkService(
            localCalendarEvents: localEvents,
            todoRepository: todoRepository,
          ),
      reminderSync:
          reminderSync ?? ReminderSyncService(AppInitializer.itemReminders),
      calendarEventWriter: CalendarEventWriteService(
        deviceCalendar: calendarService,
        localEvents: localEvents,
      ),
      dayStatusNotifications: dayStatusNotifications,
      dayStatusHomeWidget: dayStatusHomeWidget,
    );
    _deps = deps;
    _loader = DashboardDataLoader(deps);
    _tasks = DashboardTaskMutations(deps);
    _calendar = DashboardCalendarMutations(deps);

    on<LoadDashboardData>(_onLoadDashboardData);
    on<SelectDashboardDate>(_onSelectDashboardDate);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    on<PostponeTaskToNextDay>(_onPostponeTaskToNextDay);
    on<PostponeTask>(_onPostponeTask);
    on<ReorderChildTasks>(_onReorderChildTasks);
    on<LinkTaskAsChild>(_onLinkTaskAsChild);
    on<DetachTaskFromParent>(_onDetachTaskFromParent);
    on<DeleteTaskAttachment>(_onDeleteTaskAttachment);
    on<RestoreTaskAttachment>(_onRestoreTaskAttachment);
    on<UpdateTaskAttachment>(_onUpdateTaskAttachment);
    on<ToggleAttachmentChecklistItem>(_onToggleAttachmentChecklistItem);
    on<LinkTaskToCalendarEvent>(_onLinkTaskToCalendarEvent);
    on<UnlinkTaskFromCalendarEvent>(_onUnlinkTaskFromCalendarEvent);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<DeleteCalendarEvent>(_onDeleteCalendarEvent);
    on<RestoreDeletedTask>(_onRestoreDeletedTask);
    on<RestoreDeletedCalendarEvent>(_onRestoreDeletedCalendarEvent);
    on<ExpandDashboardTask>(_onExpandDashboardTask);
    on<ClearExpandedDashboardTask>(_onClearExpandedDashboardTask);
  }

  late final DashboardDependencies _deps;
  late final DashboardDataLoader _loader;
  late final DashboardTaskMutations _tasks;
  late final DashboardCalendarMutations _calendar;

  DashboardDependencies get dependencies => _deps;

  final DayStatusNotificationController? _dayStatusNotifications;
  final DayStatusHomeWidgetService? _dayStatusHomeWidget;

  DateTime _selectedDate;

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    _selectedDate = _resolveSelectedDate(event.selectedDate);
    emit(const DashboardLoading());

    try {
      final DashboardLoadPayload payload = await _loader.loadFull(
        selectedDate: _selectedDate,
        calendarIdsFromEvent: event.selectedCalendarIds,
      );
      emit(dashboardLoadedFromPayload(payload));
      _syncDayStatusNotification();
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onSelectDashboardDate(
    SelectDashboardDate event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboardData(selectedDate: event.date));
  }

  Future<void> _runTaskMutation(
    DashboardLoaded current,
    Emitter<DashboardState> emit,
    Future<void> Function() mutate,
  ) async {
    try {
      await mutate();
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onPostponeTaskToNextDay(
    PostponeTaskToNextDay event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      final bool changed = await _tasks.postponeToNextDay(
        taskId: event.taskId,
        referenceDate: current.selectedDate,
      );
      if (!changed) {
        return;
      }
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onPostponeTask(
    PostponeTask event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      final bool changed = await _tasks.postpone(
        taskId: event.taskId,
        newDueDate: event.newDueDate,
      );
      if (!changed) {
        return;
      }
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onReorderChildTasks(
    ReorderChildTasks event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(current, emit, () async {
      await _tasks.reorderChildTasks(
        parentTaskId: event.parentTaskId,
        orderedChildIds: event.orderedChildIds,
      );
    });
  }

  Future<void> _onLinkTaskAsChild(
    LinkTaskAsChild event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      final bool ok = await _tasks.linkAsChild(
        childTaskId: event.childTaskId,
        parentTaskId: event.parentTaskId,
      );
      if (!ok) {
        return;
      }
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onDetachTaskFromParent(
    DetachTaskFromParent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.detachFromParent(event.childTaskId),
    );
  }

  Future<void> _onDeleteTaskAttachment(
    DeleteTaskAttachment event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.deleteAttachment(event.attachmentId),
    );
  }

  Future<void> _onRestoreTaskAttachment(
    RestoreTaskAttachment event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.restoreAttachment(event.attachment),
    );
  }

  Future<void> _onUpdateTaskAttachment(
    UpdateTaskAttachment event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.updateAttachment(event.attachment),
    );
  }

  Future<void> _onToggleAttachmentChecklistItem(
    ToggleAttachmentChecklistItem event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      final bool changed = await _tasks.toggleAttachmentChecklistItem(
        attachmentId: event.attachmentId,
        itemLocalId: event.itemLocalId,
      );
      if (!changed) {
        return;
      }
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onLinkTaskToCalendarEvent(
    LinkTaskToCalendarEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(current, emit, () async {
      await _tasks.linkToCalendarEvent(
        taskId: event.taskId,
        eventId: event.eventId,
      );
    });
  }

  Future<void> _onUnlinkTaskFromCalendarEvent(
    UnlinkTaskFromCalendarEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.unlinkFromCalendarEvent(event.taskId),
    );
  }

  Future<void> _onDeleteTask(
    DeleteTask event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.deleteTask(event.taskId),
    );
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(current, emit, () async {
      await _calendar.deleteCalendarEvent(
        event.eventId,
        thisInstanceOnly: event.thisInstanceOnly,
      );
    });
  }

  Future<void> _onRestoreDeletedTask(
    RestoreDeletedTask event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _tasks.restoreDeletedTask(event.snapshot),
    );
  }

  Future<void> _onRestoreDeletedCalendarEvent(
    RestoreDeletedCalendarEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    await _runTaskMutation(
      current,
      emit,
      () => _calendar.restoreDeletedEvent(event.snapshot),
    );
  }

  Future<void> _onUpdateTask(
    UpdateTask event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      final bool ok = await _tasks.updateTaskFields(event.task);
      if (!ok) {
        return;
      }
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  void _onExpandDashboardTask(
    ExpandDashboardTask event,
    Emitter<DashboardState> emit,
  ) {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    emit(current.copyWith(expandedTaskId: event.taskId));
  }

  void _onClearExpandedDashboardTask(
    ClearExpandedDashboardTask event,
    Emitter<DashboardState> emit,
  ) {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }
    if (current.expandedTaskId == null) {
      return;
    }
    emit(current.copyWith(clearExpandedTaskId: true));
  }

  Future<void> _emitReloadedTasks(
    DashboardLoaded current,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardTaskSnapshot tasks = await _loader.loadTaskSnapshot(
      selectedDate: current.selectedDate,
      calendarIds: current.selectedCalendarIds,
      refreshMarkers: true,
    );
    final DashboardLocalCalendarSlice local = await _loader.loadLocalCalendar(
      current.selectedDate,
    );
    emit(
      dashboardLoadedAfterTaskMutation(
        current: current,
        tasks: tasks,
        visibleCalendarEvents: local.visibleOnSelectedDay,
        localCalendarEventById: local.localCalendarEventById,
      ),
    );
    _syncDayStatusNotification();
  }

  void _syncDayStatusNotification() {
    final DayStatusNotificationController? controller = _dayStatusNotifications;
    if (controller != null) {
      unawaited(controller.syncTodayStatus());
    }
    final DayStatusHomeWidgetService? widget = _dayStatusHomeWidget;
    if (widget != null) {
      unawaited(widget.syncToday());
    }
  }

  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletion event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      final task = await _tasks.toggleCompletion(event.taskId);
      if (task == null) {
        return;
      }
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  DateTime _resolveSelectedDate(DateTime? fromEvent) {
    if (fromEvent != null) {
      return AppDateUtils.startOfDay(fromEvent);
    }
    final DashboardState current = state;
    if (current is DashboardLoaded) {
      return current.selectedDate;
    }
    return _selectedDate;
  }
}
