import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:smart_planner/core/di/app_dependencies.dart';
import 'package:smart_planner/core/finance/currency_preferences_repository.dart';
import 'package:smart_planner/core/localization/locale_preferences_repository.dart';
import 'package:smart_planner/core/theme/app_theme.dart';
import 'package:smart_planner/core/theme/theme_preferences_repository.dart';

import 'package:smart_planner/features/attachment_templates/data/repositories/attachment_template_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_event_write_service.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/event_calendar_sync_service.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/data/task_event_link_service.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/deep_links/data/deep_link_service.dart';
import 'package:smart_planner/features/deep_links/presentation/deep_link_dispatcher.dart';
import 'package:smart_planner/features/finance/domain/repositories/payment_repository.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/day_status_service_host.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

/// Root navigator for deep-link routing to the dashboard.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class DayLinxApp extends StatelessWidget {
  const DayLinxApp({
    required this.dependencies,
    required this.localePreferences,
    required this.themePreferences,
    this.deepLinkService,
    super.key,
  });

  final AppDependencies dependencies;
  final LocalePreferencesRepository localePreferences;
  final ThemePreferencesRepository themePreferences;
  final DeepLinkService? deepLinkService;

  @override
  Widget build(BuildContext context) {
    final AppDependencies deps = dependencies;
    final DeepLinkService deepLinks = deepLinkService ?? deps.deepLinks;

    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<TodoRepository>.value(value: deps.todoRepository),
        RepositoryProvider<TaskAttachmentRepository>.value(
          value: deps.attachmentRepository,
        ),
        RepositoryProvider<CalendarService>.value(value: deps.calendarService),
        RepositoryProvider<DeviceCalendarService>.value(
          value: deps.calendarService,
        ),
        RepositoryProvider<CalendarEventWriteService>.value(
          value: deps.calendarEventWriter,
        ),
        RepositoryProvider<EventCalendarSyncService>.value(
          value: deps.eventCalendarSync,
        ),
        RepositoryProvider<DashboardDayMarkersRepository>.value(
          value: deps.dayMarkersRepository,
        ),
        RepositoryProvider<CalendarPreferencesRepository>.value(
          value: deps.calendarPreferences,
        ),
        RepositoryProvider<LocalCalendarEventRepository>.value(
          value: deps.localCalendarEventRepository,
        ),
        RepositoryProvider<EventAttachmentRepository>.value(
          value: deps.eventAttachmentRepository,
        ),
        RepositoryProvider<UiTemplateRepository>.value(
          value: deps.uiTemplateRepository,
        ),
        RepositoryProvider<AttachmentTemplateRepository>.value(
          value: deps.attachmentTemplateRepository,
        ),
        RepositoryProvider<CategoryRepository>.value(
          value: deps.categoryRepository,
        ),
        RepositoryProvider<CategoryTagService>.value(
          value: deps.categoryTagService,
        ),
        RepositoryProvider<PaymentRepository>.value(
          value: deps.paymentRepository,
        ),
        RepositoryProvider<CurrencyPreferencesRepository>.value(
          value: deps.currencyPreferences,
        ),
        RepositoryProvider<LocalePreferencesRepository>.value(
          value: localePreferences,
        ),
        RepositoryProvider<ThemePreferencesRepository>.value(
          value: themePreferences,
        ),
        RepositoryProvider<NotificationPreferencesRepository>.value(
          value: deps.notificationPreferences,
        ),
        RepositoryProvider<DayStatusNotificationController>.value(
          value: deps.dayStatusNotifications,
        ),
        RepositoryProvider<DayStatusHomeWidgetService>.value(
          value: deps.dayStatusHomeWidget,
        ),
        RepositoryProvider<ItemReminderScheduler>.value(
          value: deps.itemReminders,
        ),
        RepositoryProvider<ReminderSyncService>.value(value: deps.reminderSync),
        RepositoryProvider<TaskEventLinkService>.value(
          value: deps.taskEventLinkService,
        ),
        RepositoryProvider<DeepLinkService>.value(value: deepLinks),
      ],
      child: ListenableBuilder(
        listenable: themePreferences.themeMode,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            title: 'app_title'.tr(),
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themePreferences.themeMode.value,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              ...context.localizationDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: BlocProvider<DashboardBloc>(
              create: (_) => DashboardBloc(
                todoRepository: deps.todoRepository,
                attachmentRepository: deps.attachmentRepository,
                calendarService: deps.calendarService,
                calendarPreferences: deps.calendarPreferences,
                localCalendarEventRepository: deps.localCalendarEventRepository,
                dayMarkersRepository: deps.dayMarkersRepository,
                dayStatusNotifications: deps.dayStatusNotifications,
                dayStatusHomeWidget: deps.dayStatusHomeWidget,
                reminderSync: deps.reminderSync,
                taskEventLinkService: deps.taskEventLinkService,
                eventAttachmentRepository: deps.eventAttachmentRepository,
              )..add(const LoadDashboardData()),
              child: DeepLinkDispatcher(
                deepLinkService: deepLinks,
                child: const DayStatusServiceHost(
                  child: DashboardScreen(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
