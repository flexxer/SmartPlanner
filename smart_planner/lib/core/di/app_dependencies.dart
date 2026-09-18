import 'package:smart_planner/core/app_initializer.dart';
import 'package:smart_planner/core/finance/currency_preferences_repository.dart';
import 'package:smart_planner/features/attachment_templates/data/repositories/attachment_template_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_event_write_service.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/event_calendar_sync_service.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/data/task_event_link_service.dart';
import 'package:smart_planner/features/categories/data/category_repository_impl.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';
import 'package:smart_planner/features/deep_links/data/deep_link_service.dart';
import 'package:smart_planner/features/finance/data/payment_repository_impl.dart';
import 'package:smart_planner/features/finance/domain/repositories/payment_repository.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

/// Composition root: constructs and owns the singleton graph of repositories
/// and services used across the app.
class AppDependencies {
  AppDependencies() {
    attachmentRepository = TaskAttachmentRepository();
    todoRepository = TodoRepository(attachmentRepository: attachmentRepository);
    calendarService = CalendarService();
    calendarPreferences = CalendarPreferencesRepository();
    localCalendarEventRepository = LocalCalendarEventRepository();
    eventAttachmentRepository = EventAttachmentRepository();
    uiTemplateRepository = UiTemplateRepository();
    attachmentTemplateRepository = AttachmentTemplateRepository();
    categoryRepository = CategoryRepositoryImpl();
    categoryTagService = CategoryTagService(categoryRepository: categoryRepository);
    paymentRepository = PaymentRepositoryImpl();
    currencyPreferences = CurrencyPreferencesRepository();
    dayMarkersRepository = DashboardDayMarkersRepository(
      todoRepository: todoRepository,
      localCalendarEventRepository: localCalendarEventRepository,
    );
    notificationPreferences = NotificationPreferencesRepository();
    deepLinks = DeepLinkService();
    dayStatusTodayLoader = DayStatusTodayLoader(
      todoRepository: todoRepository,
      localCalendarEvents: localCalendarEventRepository,
    );
    dayStatusNotifications = DayStatusNotificationController(
      todayLoader: dayStatusTodayLoader,
      preferences: notificationPreferences,
    );
    dayStatusHomeWidget =
        DayStatusHomeWidgetService(loader: dayStatusTodayLoader);
    itemReminders = AppInitializer.itemReminders;
    reminderSync = ReminderSyncService(itemReminders);
    taskEventLinkService = TaskEventLinkService(
      localCalendarEvents: localCalendarEventRepository,
      todoRepository: todoRepository,
    );
    eventCalendarSync = EventCalendarSyncService(
      deviceCalendar: calendarService,
      localEvents: localCalendarEventRepository,
    );
    calendarEventWriter = CalendarEventWriteService(
      deviceCalendar: calendarService,
      localEvents: localCalendarEventRepository,
      syncService: eventCalendarSync,
    );
  }

  late final TaskAttachmentRepository attachmentRepository;
  late final TodoRepository todoRepository;
  late final CalendarService calendarService;
  late final CalendarPreferencesRepository calendarPreferences;
  late final LocalCalendarEventRepository localCalendarEventRepository;
  late final EventAttachmentRepository eventAttachmentRepository;
  late final UiTemplateRepository uiTemplateRepository;
  late final AttachmentTemplateRepository attachmentTemplateRepository;
  late final CategoryRepository categoryRepository;
  late final CategoryTagService categoryTagService;
  late final PaymentRepository paymentRepository;
  late final CurrencyPreferencesRepository currencyPreferences;
  late final DashboardDayMarkersRepository dayMarkersRepository;
  late final NotificationPreferencesRepository notificationPreferences;
  late final DeepLinkService deepLinks;
  late final DayStatusTodayLoader dayStatusTodayLoader;
  late final DayStatusNotificationController dayStatusNotifications;
  late final DayStatusHomeWidgetService dayStatusHomeWidget;
  late final ItemReminderScheduler itemReminders;
  late final ReminderSyncService reminderSync;
  late final TaskEventLinkService taskEventLinkService;
  late final CalendarEventWriteService calendarEventWriter;
  late final EventCalendarSyncService eventCalendarSync;
}
