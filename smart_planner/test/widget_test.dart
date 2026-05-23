import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

void main() {
  testWidgets('Dashboard renders app bar and loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(
            todoRepository: TodoRepository(),
            calendarService: DeviceCalendarService(),
          ),
          child: const DashboardScreen(),
        ),
      ),
    );

    expect(find.text('Smart Planner'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
