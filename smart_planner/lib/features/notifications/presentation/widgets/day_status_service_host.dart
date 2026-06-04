import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/app_initializer.dart';
import 'package:smart_planner/core/timezone/timezone_monitor.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/deep_links/data/deep_link_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';

/// Restores day-status FGS / widget on start and refreshes them when app resumes.
class DayStatusServiceHost extends StatefulWidget {
  const DayStatusServiceHost({required this.child, super.key});

  final Widget child;

  @override
  State<DayStatusServiceHost> createState() => _DayStatusServiceHostState();
}

class _DayStatusServiceHostState extends State<DayStatusServiceHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }

  Future<void> _bootstrap() async {
    if (!mounted) {
      return;
    }
    await _syncDayStatusSurfaces();
    if (mounted) {
      await context.read<DeepLinkService>().handleAppResumed();
    }
  }

  Future<void> _onResumed() async {
    if (!mounted) {
      return;
    }

    final bool timezoneChanged = await TimezoneMonitor.applyIfChanged();
    if (timezoneChanged) {
      await AppInitializer.itemReminders.rescheduleAll();
    }

    await _syncDayStatusSurfaces();
    await context.read<DeepLinkService>().handleAppResumed();
    if (mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
    }
  }

  Future<void> _syncDayStatusSurfaces() async {
    if (!mounted) {
      return;
    }
    unawaited(
      context.read<DayStatusNotificationController>().ensureStartedIfEnabled(),
    );
    unawaited(context.read<DayStatusHomeWidgetService>().syncToday());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
