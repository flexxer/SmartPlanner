import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:smart_planner/core/localization/locale_preferences_repository.dart';

import 'package:smart_planner/core/theme/app_theme.dart';

import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';

import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';

import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';

import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';

import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';

import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/day_status_service_host.dart';

import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/deep_links/data/deep_link_service.dart';
import 'package:smart_planner/features/deep_links/presentation/deep_link_dispatcher.dart';

import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';

import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';

import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';



/// Root navigator for deep-link routing to the dashboard.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class DayLinxApp extends StatelessWidget {

  const DayLinxApp({

    required this.localePreferences,

    this.deepLinkService,

    super.key,

  });



  final LocalePreferencesRepository localePreferences;

  final DeepLinkService? deepLinkService;



  @override

  Widget build(BuildContext context) {

    final TodoRepository todoRepository = TodoRepository();

    final TaskAttachmentRepository attachmentRepository =

        TaskAttachmentRepository();

    final CalendarService calendarService = CalendarService();

    final CalendarPreferencesRepository calendarPreferences =

        CalendarPreferencesRepository();

    final LocalCalendarEventRepository localCalendarEventRepository =

        LocalCalendarEventRepository();

    final UiTemplateRepository uiTemplateRepository = UiTemplateRepository();

    final DashboardDayMarkersRepository dayMarkersRepository =

        DashboardDayMarkersRepository(

      todoRepository: todoRepository,

      calendarService: calendarService,

    );

    final NotificationPreferencesRepository notificationPreferences =

        NotificationPreferencesRepository();

    final DeepLinkService deepLinks = deepLinkService ?? DeepLinkService();

    final DayStatusNotificationController dayStatusNotifications =

        DayStatusNotificationController(

      todoRepository: todoRepository,

      calendarService: calendarService,

      preferences: notificationPreferences,

      calendarPreferences: calendarPreferences,

      localCalendarEvents: localCalendarEventRepository,

    );



    return MultiRepositoryProvider(

      providers: <RepositoryProvider<dynamic>>[

        RepositoryProvider<TodoRepository>.value(value: todoRepository),

        RepositoryProvider<TaskAttachmentRepository>.value(

          value: attachmentRepository,

        ),

        RepositoryProvider<CalendarService>.value(

          value: calendarService,

        ),

        RepositoryProvider<DeviceCalendarService>.value(

          value: calendarService,

        ),

        RepositoryProvider<DashboardDayMarkersRepository>.value(

          value: dayMarkersRepository,

        ),

        RepositoryProvider<CalendarPreferencesRepository>.value(

          value: calendarPreferences,

        ),

        RepositoryProvider<LocalCalendarEventRepository>.value(

          value: localCalendarEventRepository,

        ),

        RepositoryProvider<UiTemplateRepository>.value(

          value: uiTemplateRepository,

        ),

        RepositoryProvider<LocalePreferencesRepository>.value(

          value: localePreferences,

        ),

        RepositoryProvider<NotificationPreferencesRepository>.value(

          value: notificationPreferences,

        ),

        RepositoryProvider<DayStatusNotificationController>.value(

          value: dayStatusNotifications,

        ),

        RepositoryProvider<DeepLinkService>.value(value: deepLinks),

      ],

      child: MaterialApp(

        navigatorKey: rootNavigatorKey,

        title: 'app_title'.tr(),

        theme: AppTheme.light,

        darkTheme: AppTheme.dark,

        themeMode: ThemeMode.system,

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

            todoRepository: todoRepository,

            attachmentRepository: attachmentRepository,

            calendarService: calendarService,

            dayMarkersRepository: dayMarkersRepository,

            dayStatusNotifications: dayStatusNotifications,

          )..add(const LoadDashboardData()),

          child: DeepLinkDispatcher(
            navigatorKey: rootNavigatorKey,
            deepLinkService: deepLinks,
            child: const DayStatusServiceHost(
              child: DashboardScreen(),
            ),
          ),

        ),

      ),

    );

  }

}


