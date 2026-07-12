import 'package:smart_planner/features/calendar_integration/data/calendar_event_write_service.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/data/task_event_link_service.dart';
import 'package:smart_planner/features/categories/data/category_preferences_repository.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

/// Shared repositories and services for dashboard data loading and mutations.
class DashboardDependencies {
  const DashboardDependencies({
    required this.todoRepository,
    required this.calendarService,
    required this.calendarPreferences,
    required this.localCalendarEvents,
    required this.dayMarkersRepository,
    required this.attachmentRepository,
    required this.eventAttachments,
    required this.taskEventLinks,
    required this.reminderSync,
    required this.calendarEventWriter,
    required this.categoryTagService,
    required this.categoryPreferences,
    this.dayStatusNotifications,
    this.dayStatusHomeWidget,
  });

  final TodoRepository todoRepository;
  final CalendarService calendarService;
  final CalendarPreferencesRepository calendarPreferences;
  final LocalCalendarEventRepository localCalendarEvents;
  final DashboardDayMarkersRepository dayMarkersRepository;
  final TaskAttachmentRepository attachmentRepository;
  final EventAttachmentRepository eventAttachments;
  final TaskEventLinkService taskEventLinks;
  final ReminderSyncService reminderSync;
  final CalendarEventWriteService calendarEventWriter;
  final CategoryTagService categoryTagService;
  final CategoryPreferencesRepository categoryPreferences;
  final DayStatusNotificationController? dayStatusNotifications;
  final DayStatusHomeWidgetService? dayStatusHomeWidget;
}
