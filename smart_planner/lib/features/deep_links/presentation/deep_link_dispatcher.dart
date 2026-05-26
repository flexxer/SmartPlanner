import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/deep_links/data/deep_link_service.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_create_action.dart';
/// Listens for deep links and opens create sheets on the dashboard.
class DeepLinkDispatcher extends StatefulWidget {
  const DeepLinkDispatcher({
    required this.navigatorKey,
    required this.deepLinkService,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final DeepLinkService deepLinkService;
  final Widget child;

  @override
  State<DeepLinkDispatcher> createState() => _DeepLinkDispatcherState();
}

class _DeepLinkDispatcherState extends State<DeepLinkDispatcher> {
  StreamSubscription<DeepLinkCreateAction>? _subscription;
  DeepLinkCreateAction? _pending;
  int _dispatchAttempts = 0;
  static const int _maxDispatchAttempts = 30;

  @override
  void initState() {
    super.initState();
    unawaited(widget.deepLinkService.initialize());
    _subscription = widget.deepLinkService.actions.listen(_onDeepLink);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _onDeepLink(DeepLinkCreateAction action) {
    _pending = action;
    _dispatchAttempts = 0;
    _scheduleDispatch();
  }

  void _scheduleDispatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_dispatch()));
  }

  Future<void> _dispatch() async {
    final DeepLinkCreateAction? action = _pending;
    if (action == null) {
      return;
    }

    final BuildContext? navContext = widget.navigatorKey.currentContext;
    if (navContext == null) {
      _retryLater();
      return;
    }

    if (!navContext.mounted) {
      _retryLater();
      return;
    }

    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    }

    if (!navContext.mounted) {
      _retryLater();
      return;
    }

    final DashboardState dashboardState = navContext.read<DashboardBloc>().state;
    if (dashboardState is! DashboardLoaded) {
      _retryLater();
      return;
    }

    _pending = null;
    _dispatchAttempts = 0;

    final List<String> selectedCalendarIds = dashboardState.selectedCalendarIds;

    switch (action) {
      case DeepLinkCreateTaskAction():
        await DashboardScreen.openTaskFormSheet(
          navContext,
          initialTitle: action.title,
          initialPriority: action.priority,
          initialDueDate: dashboardState.selectedDate,
          selectedCalendarIds: selectedCalendarIds,
        );
      case DeepLinkCreateEventAction():
        final DateTime day = dashboardState.selectedDate;
        await DashboardScreen.openEventFormSheet(
          navContext,
          initialDay: day,
          initialTitle: action.title,
          initialStart: action.start,
          initialEnd: action.end,
          selectedCalendarIds: selectedCalendarIds,
        );
    }
  }

  void _retryLater() {
    if (_pending == null) {
      return;
    }
    _dispatchAttempts++;
    if (_dispatchAttempts >= _maxDispatchAttempts) {
      _pending = null;
      return;
    }
    _scheduleDispatch();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
