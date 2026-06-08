import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_load_models.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';

/// Maps loaded dashboard slices into [DashboardLoaded].
DashboardLoaded dashboardLoadedFromPayload(DashboardLoadPayload payload) {
  return DashboardLoaded(
    tasks: payload.tasks.tasks,
    completedTasks: payload.tasks.completedTasks,
    overdueTasks: payload.tasks.overdueTasks,
    undatedTasks: payload.tasks.undatedTasks,
    calendarEvents: payload.calendar.visibleCalendarEvents,
    selectedDate: payload.selectedDate,
    selectedCalendarIds: payload.selectedCalendarIds,
    calendarMessage: payload.calendar.calendarMessage,
    localCalendarEventById: payload.calendar.localCalendarEventById,
    childTasksByParentId: payload.tasks.childTasksByParentId,
    attachmentsByTaskId: payload.tasks.attachmentsByTaskId,
    dayMarkers: payload.tasks.dayMarkers,
    linkedCalendarsById: payload.linkedCalendarsById,
  );
}

DashboardLoaded dashboardLoadedAfterTaskMutation({
  required DashboardLoaded current,
  required DashboardTaskSnapshot tasks,
  required List<CalendarEvent> visibleCalendarEvents,
  required Map<Id, CalendarEvent> localCalendarEventById,
}) {
  return current.copyWith(
    tasks: tasks.tasks,
    completedTasks: tasks.completedTasks,
    overdueTasks: tasks.overdueTasks,
    undatedTasks: tasks.undatedTasks,
    calendarEvents: visibleCalendarEvents,
    localCalendarEventById: localCalendarEventById,
    childTasksByParentId: tasks.childTasksByParentId,
    attachmentsByTaskId: tasks.attachmentsByTaskId,
    dayMarkers: tasks.dayMarkers,
  );
}
