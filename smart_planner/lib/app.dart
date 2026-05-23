import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_planner/core/theme/app_theme.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

class SmartPlannerApp extends StatelessWidget {
  const SmartPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final TodoRepository todoRepository = TodoRepository();
    final TaskAttachmentRepository attachmentRepository =
        TaskAttachmentRepository();
    final DeviceCalendarService calendarService = DeviceCalendarService();

    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<TodoRepository>.value(value: todoRepository),
        RepositoryProvider<TaskAttachmentRepository>.value(
          value: attachmentRepository,
        ),
      ],
      child: MaterialApp(
        title: 'Smart Planner',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: const Locale('ru'),
        supportedLocales: const <Locale>[Locale('ru'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(
            todoRepository: todoRepository,
            attachmentRepository: attachmentRepository,
            calendarService: calendarService,
          )..add(const LoadDashboardData()),
          child: const DashboardScreen(),
        ),
      ),
    );
  }
}
