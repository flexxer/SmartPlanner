import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';

/// Restores the day-status foreground service after app start when enabled.
class DayStatusServiceHost extends StatefulWidget {
  const DayStatusServiceHost({required this.child, super.key});

  final Widget child;

  @override
  State<DayStatusServiceHost> createState() => _DayStatusServiceHostState();
}

class _DayStatusServiceHostState extends State<DayStatusServiceHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
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
