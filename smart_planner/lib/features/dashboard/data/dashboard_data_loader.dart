import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/linked_calendar_ids_resolver.dart';
import 'package:smart_planner/features/categories/domain/category_filter_utils.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_dependencies.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_load_models.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_selection.dart';

/// Loads dashboard task/calendar slices and resolves calendar selection.
class DashboardDataLoader {
  DashboardDataLoader(this._deps);

  final DashboardDependencies _deps;

  Future<DashboardLoadPayload> loadFull({
    required DateTime selectedDate,
    List<String>? calendarIdsFromEvent,
    List<Id>? categoryIdsFromEvent,
  }) async {
    final List<String> selectedCalendarIds =
        await resolveSelectedCalendarIds(calendarIdsFromEvent);
    final List<Id> selectedCategoryIds =
        await resolveSelectedCategoryIds(categoryIdsFromEvent);
    final DashboardCalendarSnapshot calendar = await loadCalendarSnapshot(
      selectedDate: selectedDate,
      selectedCategoryIds: selectedCategoryIds,
    );
    final DashboardTaskSnapshot tasks = await loadTaskSnapshot(
      selectedDate: selectedDate,
      calendarIds: selectedCalendarIds,
      selectedCategoryIds: selectedCategoryIds,
      refreshMarkers: true,
    );
    final Map<String, DeviceCalendarInfo> linkedCalendarsById =
        await loadLinkedCalendarsById(selectedCalendarIds);

    return DashboardLoadPayload(
      tasks: tasks,
      calendar: calendar,
      linkedCalendarsById: linkedCalendarsById,
      selectedDate: selectedDate,
      selectedCalendarIds: selectedCalendarIds,
      selectedCategoryIds: selectedCategoryIds,
    );
  }

  Future<DashboardTaskSnapshot> loadTaskSnapshot({
    required DateTime selectedDate,
    required List<String> calendarIds,
    List<Id> selectedCategoryIds = const <Id>[],
    bool refreshMarkers = false,
  }) async {
    final ({DateTime start, DateTime end}) markerRange =
        AppDateUtils.dateStripMarkerRange(selectedDate);

    if (refreshMarkers) {
      _deps.dayMarkersRepository.invalidate();
    }

    final List<Object> parallel = await Future.wait<Object>(
      <Future<Object>>[
        _deps.todoRepository.getUncompletedTasksForDate(selectedDate),
        _deps.todoRepository.getCompletedTasksForDate(selectedDate),
        _loadOverdueTasks(selectedDate),
        _deps.todoRepository.getUndatedTasks(),
        _deps.dayMarkersRepository.loadForRange(
          rangeStart: markerRange.start,
          rangeEnd: markerRange.end,
          calendarIds: calendarIds,
        ),
      ],
    );

    List<Task> tasks = parallel[0] as List<Task>;
    List<Task> completedTasks = parallel[1] as List<Task>;
    List<Task> overdueTasks = parallel[2] as List<Task>;
    List<Task> undatedTasks = parallel[3] as List<Task>;
    final Map<int, DayActivityMarker> dayMarkers =
        parallel[4] as Map<int, DayActivityMarker>;

    final List<Id> allTaskIds = parentTaskIdsFor(
      tasks,
      completedTasks,
      overdueTasks,
      undatedTasks,
    );
    final Map<Id, List<Category>> categoriesByTaskId =
        await _deps.categoryTagService.getTagsForEntities(
      entityType: TaggedEntityType.task,
      entityIds: allTaskIds,
    );
    final Map<int, List<Id>> tagIdsByTaskId =
        CategoryFilterUtils.tagIdsFromCategoriesByEntity(categoriesByTaskId);

    if (selectedCategoryIds.isNotEmpty) {
      tasks = CategoryFilterUtils.filterEntities<Task>(
        items: tasks,
        idFor: (Task task) => task.id,
        selectedCategoryIds: selectedCategoryIds,
        tagIdsByEntityId: tagIdsByTaskId,
      );
      completedTasks = CategoryFilterUtils.filterEntities<Task>(
        items: completedTasks,
        idFor: (Task task) => task.id,
        selectedCategoryIds: selectedCategoryIds,
        tagIdsByEntityId: tagIdsByTaskId,
      );
      overdueTasks = CategoryFilterUtils.filterEntities<Task>(
        items: overdueTasks,
        idFor: (Task task) => task.id,
        selectedCategoryIds: selectedCategoryIds,
        tagIdsByEntityId: tagIdsByTaskId,
      );
      undatedTasks = CategoryFilterUtils.filterEntities<Task>(
        items: undatedTasks,
        idFor: (Task task) => task.id,
        selectedCategoryIds: selectedCategoryIds,
        tagIdsByEntityId: tagIdsByTaskId,
      );
    }

    final List<Id> taskIds = parentTaskIdsFor(
      tasks,
      completedTasks,
      overdueTasks,
      undatedTasks,
    );
    final Map<Id, ChildTasksBundle> childBundles =
        await _deps.todoRepository.getChildTasksBundlesForParents(taskIds);
    final Map<Id, List<TaskAttachment>> attachmentMap =
        await _deps.attachmentRepository.getAttachmentsForTasks(taskIds);

    return DashboardTaskSnapshot(
      tasks: tasks,
      completedTasks: completedTasks,
      overdueTasks: overdueTasks,
      undatedTasks: undatedTasks,
      childTasksByParentId: childBundles,
      attachmentsByTaskId: attachmentMap,
      dayMarkers: dayMarkers,
      categoriesByTaskId: categoriesByTaskId,
    );
  }

  Future<DashboardCalendarSnapshot> loadCalendarSnapshot({
    required DateTime selectedDate,
    List<Id> selectedCategoryIds = const <Id>[],
  }) async {
    _deps.dayMarkersRepository.invalidate();

    final List<CalendarEvent> allStored =
        await _deps.localCalendarEvents.getAll();
    List<CalendarEvent> visible = VisibleCalendarEventsMerger.fromStored(
      selectedDay: selectedDate,
      allStored: allStored,
    );

    if (selectedCategoryIds.isNotEmpty) {
      final Map<int, List<Id>> tagIdsByEventId =
          await _deps.categoryTagService.getTagIdsForEntities(
        entityType: TaggedEntityType.calendarEvent,
        entityIds: visible.map((CalendarEvent event) => event.id),
      );
      visible = CategoryFilterUtils.filterEntities<CalendarEvent>(
        items: visible,
        idFor: (CalendarEvent event) => event.id,
        selectedCategoryIds: selectedCategoryIds,
        tagIdsByEntityId: tagIdsByEventId,
      );
    }

    return DashboardCalendarSnapshot(
      deviceEvents: const <CalendarEvent>[],
      visibleCalendarEvents: visible,
      localCalendarEventById: <Id, CalendarEvent>{
        for (final CalendarEvent event in allStored) event.id: event,
      },
    );
  }

  Future<Map<String, DeviceCalendarInfo>> loadLinkedCalendarsById(
    List<String> calendarIds,
  ) async {
    final LinkedCalendarsLoadResult result = await LinkedCalendarsLoader(
      calendarService: _deps.calendarService,
      preferences: _deps.calendarPreferences,
    ).load(selectedCalendarIds: calendarIds);
    return Map<String, DeviceCalendarInfo>.fromEntries(
      result.calendars.map(
        (DeviceCalendarInfo c) => MapEntry<String, DeviceCalendarInfo>(c.id, c),
      ),
    );
  }

  Future<List<String>> resolveSelectedCalendarIds(
    List<String>? calendarIdsFromEvent,
  ) async {
    if (calendarIdsFromEvent != null && calendarIdsFromEvent.isNotEmpty) {
      await _deps.calendarPreferences.saveSelectedCalendarIds(
        calendarIdsFromEvent,
      );
    }

    return LinkedCalendarIdsResolver.resolve(
      calendarService: _deps.calendarService,
      preferences: _deps.calendarPreferences,
      overrideIds: calendarIdsFromEvent,
    );
  }

  Future<List<Task>> _loadOverdueTasks(DateTime selectedDate) async {
    if (!TaskOverdueSelection.shouldExposeOverdueTasksForSelectedDay(
      selectedDate,
    )) {
      return const <Task>[];
    }
    return _deps.todoRepository.getOverdueUncompletedTasks();
  }

  Future<List<Id>> resolveSelectedCategoryIds(
    List<Id>? categoryIdsFromEvent,
  ) async {
    if (categoryIdsFromEvent != null) {
      await _deps.categoryPreferences.saveDashboardFilterCategoryIds(
        categoryIdsFromEvent,
      );
      return categoryIdsFromEvent;
    }
    return _deps.categoryPreferences.getDashboardFilterCategoryIds();
  }

  Future<DashboardLocalCalendarSlice> loadLocalCalendar(
    DateTime selectedDay, {
    List<Id> selectedCategoryIds = const <Id>[],
  }) async {
    final DashboardCalendarSnapshot calendar = await loadCalendarSnapshot(
      selectedDate: selectedDay,
      selectedCategoryIds: selectedCategoryIds,
    );
    return DashboardLocalCalendarSlice(
      visibleOnSelectedDay: calendar.visibleCalendarEvents,
      localCalendarEventById: calendar.localCalendarEventById,
    );
  }

  static List<Id> parentTaskIdsFor(
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
}
