import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_selection.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required TodoRepository todoRepository,
    required CalendarService calendarService,
    CalendarPreferencesRepository? calendarPreferences,
    TaskAttachmentRepository? attachmentRepository,
    DashboardDayMarkersRepository? dayMarkersRepository,
    LocalCalendarEventRepository? localCalendarEventRepository,
    DayStatusNotificationController? dayStatusNotifications,
  })  : _todoRepository = todoRepository,
        _attachmentRepository =
            attachmentRepository ?? TaskAttachmentRepository(),
        _calendarService = calendarService,
        _calendarPreferences =
            calendarPreferences ?? CalendarPreferencesRepository(),
        _localCalendarEvents = localCalendarEventRepository ??
            LocalCalendarEventRepository(),
        _dayMarkersRepository = dayMarkersRepository ??
            DashboardDayMarkersRepository(
              todoRepository: todoRepository,
              calendarService: calendarService,
            ),
        _dayStatusNotifications = dayStatusNotifications,
        super(const DashboardInitial()) {
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
    on<ExpandDashboardTask>(_onExpandDashboardTask);
    on<ClearExpandedDashboardTask>(_onClearExpandedDashboardTask);
  }

  final TodoRepository _todoRepository;
  final TaskAttachmentRepository _attachmentRepository;
  final CalendarService _calendarService;
  final CalendarPreferencesRepository _calendarPreferences;
  final LocalCalendarEventRepository _localCalendarEvents;
  final DashboardDayMarkersRepository _dayMarkersRepository;
  final DayStatusNotificationController? _dayStatusNotifications;

  List<String> _selectedCalendarIds = <String>[];
  DateTime _selectedDate = AppDateUtils.startOfDay(DateTime.now());

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    _selectedDate = _resolveSelectedDate(event.selectedDate);
    emit(const DashboardLoading());

    try {
      final List<String> calendarIds = await _resolveCalendarIds(
        event.selectedCalendarIds,
      );
      final ({DateTime start, DateTime end}) markerRange =
          AppDateUtils.dateStripMarkerRange(_selectedDate);

      final List<Object> parallel = await Future.wait<Object>(
        <Future<Object>>[
          _todoRepository.getUncompletedTasksForDate(_selectedDate),
          _todoRepository.getCompletedTasksForDate(_selectedDate),
          _loadOverdueTasksForSelectedDay(_selectedDate),
          _todoRepository.getUndatedTasks(),
          _dayMarkersRepository.loadForRange(
            rangeStart: markerRange.start,
            rangeEnd: markerRange.end,
            calendarIds: calendarIds,
          ),
        ],
      );

      final List<Task> tasks = parallel[0] as List<Task>;
      final List<Task> completedTasks = parallel[1] as List<Task>;
      final List<Task> overdueTasks = parallel[2] as List<Task>;
      final List<Task> undatedTasks = parallel[3] as List<Task>;
      final Map<int, DayActivityMarker> dayMarkers =
          parallel[4] as Map<int, DayActivityMarker>;

      // Device events are upserted into Isar first; then local strip reads them.
      final _DayEventsResult eventsResult = await _loadEventsForDay(
        day: _selectedDate,
        resolvedCalendarIds: calendarIds,
      );
      final _LocalCalendarSnapshot localSnapshot =
          await _loadLocalCalendarSnapshot(_selectedDate);
      final Map<String, DeviceCalendarInfo> linkedCalendarsById =
          await _loadLinkedCalendarsById(calendarIds);

      final List<Id> taskIds = _parentTaskIdsForDashboard(
        tasks,
        completedTasks,
        overdueTasks,
        undatedTasks,
      );
      final Map<Id, ChildTasksBundle> childBundles =
          await _todoRepository.getChildTasksBundlesForParents(taskIds);
      final Map<Id, List<TaskAttachment>> attachments =
          await _attachmentRepository.getAttachmentsForTasks(taskIds);

      emit(
        DashboardLoaded(
          tasks: tasks,
          completedTasks: completedTasks,
          overdueTasks: overdueTasks,
          undatedTasks: undatedTasks,
          events: eventsResult.events,
          calendarEvents: localSnapshot.visibleOnSelectedDay,
          selectedDate: _selectedDate,
          selectedCalendarIds: _selectedCalendarIds,
          calendarMessage: eventsResult.message,
          localCalendarEventById: localSnapshot.byId,
          childTasksByParentId: childBundles,
          attachmentsByTaskId: attachments,
          dayMarkers: dayMarkers,
          linkedCalendarsById: linkedCalendarsById,
        ),
      );
      _syncDayStatusNotification();
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<Map<String, DeviceCalendarInfo>> _loadLinkedCalendarsById(
    List<String> calendarIds,
  ) async {
    final LinkedCalendarsLoadResult result = await LinkedCalendarsLoader(
      calendarService: _calendarService,
      preferences: _calendarPreferences,
    ).load(selectedCalendarIds: calendarIds);
    return Map<String, DeviceCalendarInfo>.fromEntries(
      result.calendars.map(
        (DeviceCalendarInfo c) => MapEntry<String, DeviceCalendarInfo>(c.id, c),
      ),
    );
  }

  Future<void> _onSelectDashboardDate(
    SelectDashboardDate event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboardData(selectedDate: event.date));
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
      final Task? task = await _todoRepository.getTaskById(event.taskId);
      if (task == null || task.isCompleted) {
        return;
      }

      task.postponeToNextDay(referenceDate: current.selectedDate);
      await _todoRepository.updateTask(task);

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
      final Task? task = await _todoRepository.getTaskById(event.taskId);
      if (task == null || task.isCompleted) {
        return;
      }

      task.postponeDueDate(event.newDueDate);
      await _todoRepository.updateTask(task);

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

    try {
      await _todoRepository.reorderChildTasks(
        parentTaskId: event.parentTaskId,
        orderedChildIds: event.orderedChildIds,
      );
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
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
      final bool ok = await _todoRepository.attachTaskToParent(
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

    try {
      await _todoRepository.detachTaskFromParent(event.childTaskId);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onDeleteTaskAttachment(
    DeleteTaskAttachment event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      await _attachmentRepository.delete(event.attachmentId);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onRestoreTaskAttachment(
    RestoreTaskAttachment event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      await _attachmentRepository.save(event.attachment);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onUpdateTaskAttachment(
    UpdateTaskAttachment event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      await _attachmentRepository.update(event.attachment);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
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
      final TaskAttachment? attachment =
          await _attachmentRepository.getById(event.attachmentId);
      if (attachment == null) {
        return;
      }
      if (!TaskAttachmentChecklist.toggleItem(
        attachment,
        event.itemLocalId,
      )) {
        return;
      }
      await _attachmentRepository.update(attachment);
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

    try {
      await _localCalendarEvents.linkTask(
        eventId: event.eventId,
        taskId: event.taskId,
      );
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onUnlinkTaskFromCalendarEvent(
    UnlinkTaskFromCalendarEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      await _localCalendarEvents.unlinkTask(event.taskId);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTask event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      await _localCalendarEvents.unlinkTask(event.taskId);
      await _attachmentRepository.deleteAllForTask(event.taskId);

      final List<Task> children =
          await _todoRepository.getAllChildTasks(event.taskId);
      for (final Task child in children) {
        TaskHierarchy.detach(child);
        await _todoRepository.updateTask(child);
      }

      await _todoRepository.deleteTask(event.taskId);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final DashboardState current = state;
    if (current is! DashboardLoaded) {
      return;
    }

    try {
      await _localCalendarEvents.deleteLocalEvent(event.eventId);
      await _emitReloadedTasks(current, emit);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
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
      final Task? existing = await _todoRepository.getTaskById(event.task.id);
      if (existing == null) {
        return;
      }

      existing
        ..title = event.task.title
        ..description = event.task.description
        ..dueDate = event.task.dueDate
        ..priority = event.task.priority
        ..calendarId = event.task.calendarId
        ..updatedAt = event.task.updatedAt;
      await _todoRepository.updateTask(existing);
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
    final List<Object> parallel = await Future.wait<Object>(
      <Future<Object>>[
        _todoRepository.getUncompletedTasksForDate(current.selectedDate),
        _todoRepository.getCompletedTasksForDate(current.selectedDate),
        _loadOverdueTasksForSelectedDay(current.selectedDate),
        _todoRepository.getUndatedTasks(),
      ],
    );
    final List<Task> tasks = parallel[0] as List<Task>;
    final List<Task> completedTasks = parallel[1] as List<Task>;
    final List<Task> overdueTasks = parallel[2] as List<Task>;
    final List<Task> undatedTasks = parallel[3] as List<Task>;
    final List<Id> taskIds = _parentTaskIdsForDashboard(
      tasks,
      completedTasks,
      overdueTasks,
      undatedTasks,
    );
    final Map<Id, ChildTasksBundle> childBundles =
        await _todoRepository.getChildTasksBundlesForParents(taskIds);
    final Map<Id, List<TaskAttachment>> attachments =
        await _attachmentRepository.getAttachmentsForTasks(taskIds);
    _dayMarkersRepository.invalidate();
    final ({DateTime start, DateTime end}) markerRange =
        AppDateUtils.dateStripMarkerRange(current.selectedDate);
    final Map<int, DayActivityMarker> dayMarkers =
        await _dayMarkersRepository.loadForRange(
      rangeStart: markerRange.start,
      rangeEnd: markerRange.end,
      calendarIds: current.selectedCalendarIds,
    );
    final _LocalCalendarSnapshot localSnapshot =
        await _loadLocalCalendarSnapshot(current.selectedDate);
    emit(
      current.copyWith(
        tasks: tasks,
        completedTasks: completedTasks,
        overdueTasks: overdueTasks,
        undatedTasks: undatedTasks,
        calendarEvents: localSnapshot.visibleOnSelectedDay,
        localCalendarEventById: localSnapshot.byId,
        childTasksByParentId: childBundles,
        attachmentsByTaskId: attachments,
        dayMarkers: dayMarkers,
      ),
    );
    _syncDayStatusNotification();
  }

  void _syncDayStatusNotification() {
    final DayStatusNotificationController? controller = _dayStatusNotifications;
    if (controller == null) {
      return;
    }
    unawaited(controller.syncTodayStatus());
  }

  static List<Id> _parentTaskIdsForDashboard(
    List<Task> tasks,
    List<Task> completedTasks,
    List<Task> overdueTasks,
    List<Task> undatedTasks,
  ) {
    final Set<Id> ids = <Id>{
      for (final Task t in tasks) t.id,
      for (final Task t in completedTasks) t.id,
      for (final Task t in overdueTasks) t.id,
      for (final Task t in undatedTasks) t.id,
    };
    return ids.toList(growable: false);
  }

  Future<List<Task>> _loadOverdueTasksForSelectedDay(
    DateTime selectedDate,
  ) async {
    if (!TaskOverdueSelection.shouldExposeOverdueTasksForSelectedDay(
      selectedDate,
    )) {
      return const <Task>[];
    }
    return _todoRepository.getOverdueUncompletedTasks();
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
      final Task? task = await _todoRepository.getTaskById(event.taskId);
      if (task == null) {
        return;
      }

      task.isCompleted = !task.isCompleted;
      await _todoRepository.updateTask(task);

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

  Future<_DayEventsResult> _loadEventsForDay({
    required DateTime day,
    List<String>? calendarIdsFromEvent,
    List<String>? resolvedCalendarIds,
  }) async {
    try {
      final List<String> calendarIds = resolvedCalendarIds ??
          await _resolveCalendarIds(
            calendarIdsFromEvent,
          );

      if (calendarIds.isEmpty) {
        return _DayEventsResult(
          events: <CalendarEvent>[],
          message: L10n.tr('calendar_events_error_no_access'),
        );
      }

      final List<CalendarEvent> events = await _calendarService.getEventsForDay(
        calendarIds: calendarIds,
        day: day,
      );

      await _localCalendarEvents.upsertDeviceEvents(events);

      return _DayEventsResult(events: events);
    } on CalendarPermissionDeniedException {
      return _DayEventsResult(
        events: <CalendarEvent>[],
        message: L10n.tr('calendar_events_error_android_permission'),
      );
    } on CalendarServiceException catch (e) {
      return _DayEventsResult(
        events: <CalendarEvent>[],
        message: e.toString(),
      );
    }
  }

  Future<List<String>> _resolveCalendarIds(
    List<String>? calendarIdsFromEvent,
  ) async {
    if (calendarIdsFromEvent != null && calendarIdsFromEvent.isNotEmpty) {
      _selectedCalendarIds = List<String>.from(calendarIdsFromEvent);
      await _calendarPreferences.saveSelectedCalendarIds(_selectedCalendarIds);
      return _selectedCalendarIds;
    }

    final List<String>? saved = await _calendarPreferences.getSelectedCalendarIds();
    if (saved != null && saved.isNotEmpty) {
      _selectedCalendarIds = saved;
      return _selectedCalendarIds;
    }

    final bool granted = await _calendarService.requestPermissions();
    if (!granted) {
      return <String>[];
    }

    _selectedCalendarIds = await _calendarService.resolveDefaultCalendarIds();
    if (_selectedCalendarIds.isNotEmpty) {
      await _calendarPreferences.saveSelectedCalendarIds(_selectedCalendarIds);
    }
    return _selectedCalendarIds;
  }

  Future<_LocalCalendarSnapshot> _loadLocalCalendarSnapshot(
    DateTime selectedDay,
  ) async {
    final List<CalendarEvent> allStored =
        await _localCalendarEvents.getAll();
    final List<CalendarEvent> visible = allStored
        .where(
          (CalendarEvent event) =>
              RecurrenceEvaluator.shouldShowEventOnDate(event, selectedDay),
        )
        .toList(growable: false)
      ..sort(
        (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
      );

    final Map<Id, CalendarEvent> byId = <Id, CalendarEvent>{
      for (final CalendarEvent event in allStored) event.id: event,
    };

    return _LocalCalendarSnapshot(
      visibleOnSelectedDay: visible,
      byId: byId,
    );
  }
}

class _LocalCalendarSnapshot {
  const _LocalCalendarSnapshot({
    required this.visibleOnSelectedDay,
    required this.byId,
  });

  final List<CalendarEvent> visibleOnSelectedDay;
  final Map<Id, CalendarEvent> byId;
}

class _DayEventsResult {
  const _DayEventsResult({
    required this.events,
    this.message,
  });

  final List<CalendarEvent> events;
  final String? message;
}
