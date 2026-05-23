import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
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
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required TodoRepository todoRepository,
    required CalendarService calendarService,
    CalendarPreferencesRepository? calendarPreferences,
    TaskAttachmentRepository? attachmentRepository,
    DashboardDayMarkersRepository? dayMarkersRepository,
  })  : _todoRepository = todoRepository,
        _attachmentRepository =
            attachmentRepository ?? TaskAttachmentRepository(),
        _calendarService = calendarService,
        _calendarPreferences =
            calendarPreferences ?? CalendarPreferencesRepository(),
        _dayMarkersRepository = dayMarkersRepository ??
            DashboardDayMarkersRepository(
              todoRepository: todoRepository,
              calendarService: calendarService,
            ),
        super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<SelectDashboardDate>(_onSelectDashboardDate);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    on<PostponeTaskToNextDay>(_onPostponeTaskToNextDay);
    on<PostponeTask>(_onPostponeTask);
    on<LinkTaskAsChild>(_onLinkTaskAsChild);
    on<DetachTaskFromParent>(_onDetachTaskFromParent);
    on<DeleteTaskAttachment>(_onDeleteTaskAttachment);
    on<ToggleAttachmentChecklistItem>(_onToggleAttachmentChecklistItem);
  }

  final TodoRepository _todoRepository;
  final TaskAttachmentRepository _attachmentRepository;
  final CalendarService _calendarService;
  final CalendarPreferencesRepository _calendarPreferences;
  final DashboardDayMarkersRepository _dayMarkersRepository;

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
          _loadOverdueTasksForSelectedDay(_selectedDate),
          _loadEventsForDay(
            day: _selectedDate,
            resolvedCalendarIds: calendarIds,
          ),
          _dayMarkersRepository.loadForRange(
            rangeStart: markerRange.start,
            rangeEnd: markerRange.end,
            calendarIds: calendarIds,
          ),
        ],
      );

      final List<Task> tasks = parallel[0] as List<Task>;
      final List<Task> overdueTasks = parallel[1] as List<Task>;
      final _DayEventsResult eventsResult = parallel[2] as _DayEventsResult;
      final Map<int, DayActivityMarker> dayMarkers =
          parallel[3] as Map<int, DayActivityMarker>;

      final List<Id> taskIds = _parentTaskIdsForDashboard(tasks, overdueTasks);
      final Map<Id, ChildTasksBundle> childBundles =
          await _todoRepository.getChildTasksBundlesForParents(taskIds);
      final Map<Id, List<TaskAttachment>> attachments =
          await _attachmentRepository.getAttachmentsForTasks(taskIds);

      emit(
        DashboardLoaded(
          tasks: tasks,
          overdueTasks: overdueTasks,
          events: eventsResult.events,
          selectedDate: _selectedDate,
          selectedCalendarIds: _selectedCalendarIds,
          calendarMessage: eventsResult.message,
          childTasksByParentId: childBundles,
          attachmentsByTaskId: attachments,
          dayMarkers: dayMarkers,
        ),
      );
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

  Future<void> _emitReloadedTasks(
    DashboardLoaded current,
    Emitter<DashboardState> emit,
  ) async {
    final List<Task> tasks = await _todoRepository.getUncompletedTasksForDate(
      current.selectedDate,
    );
    final List<Task> overdueTasks = await _loadOverdueTasksForSelectedDay(
      current.selectedDate,
    );
    final List<Id> taskIds = _parentTaskIdsForDashboard(tasks, overdueTasks);
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
    emit(
      current.copyWith(
        tasks: tasks,
        overdueTasks: overdueTasks,
        childTasksByParentId: childBundles,
        attachmentsByTaskId: attachments,
        dayMarkers: dayMarkers,
      ),
    );
  }

  static List<Id> _parentTaskIdsForDashboard(
    List<Task> tasks,
    List<Task> overdueTasks,
  ) {
    final Set<Id> ids = <Id>{
      for (final Task t in tasks) t.id,
      for (final Task t in overdueTasks) t.id,
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
        return const _DayEventsResult(
          events: <CalendarEvent>[],
          message:
              'Нет доступа к календарю или календари не выбраны. '
              'Откройте «Календари» в меню и включите Google-календарь.',
        );
      }

      final List<CalendarEvent> events = await _calendarService.getEventsForDay(
        calendarIds: calendarIds,
        day: day,
      );

      return _DayEventsResult(events: events);
    } on CalendarPermissionDeniedException {
      return const _DayEventsResult(
        events: <CalendarEvent>[],
        message:
            'Разрешите доступ к календарю в настройках Android '
            '(Настройки → Приложения → Smart Planner → Разрешения).',
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
}

class _DayEventsResult {
  const _DayEventsResult({
    required this.events,
    this.message,
  });

  final List<CalendarEvent> events;
  final String? message;
}
