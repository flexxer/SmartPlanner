import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/deep_links/data/deep_link_service.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_action.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
/// Listens for deep links and opens create sheets on the dashboard.
class DeepLinkDispatcher extends StatefulWidget {
  const DeepLinkDispatcher({
    required this.deepLinkService,
    required this.child,
    super.key,
  });

  final DeepLinkService deepLinkService;
  final Widget child;

  @override
  State<DeepLinkDispatcher> createState() => _DeepLinkDispatcherState();
}

class _DeepLinkDispatcherState extends State<DeepLinkDispatcher> {
  StreamSubscription<DeepLinkAction>? _subscription;
  DeepLinkAction? _pending;

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

  void _onDeepLink(DeepLinkAction action) {
    if (action is DeepLinkRefreshWidgetAction) {
      return;
    }
    _pending = action;
    _scheduleDispatch();
  }

  void _scheduleDispatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_dispatch()));
  }

  Future<void> _dispatch() async {
    final DeepLinkAction? action = _pending;
    if (action == null || !mounted) {
      return;
    }

    final DashboardState dashboardState = context.read<DashboardBloc>().state;
    if (dashboardState is! DashboardLoaded) {
      return;
    }

    _pending = null;

    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    }

    if (!mounted) {
      return;
    }

    final List<String> selectedCalendarIds = dashboardState.selectedCalendarIds;

    switch (action) {
      case DeepLinkRefreshWidgetAction():
        return;
      case DeepLinkCreateTaskAction():
        await DashboardScreen.openTaskFormSheet(
          context,
          initialTitle: action.title,
          initialPriority: action.priority,
          initialDueDate: AppDateUtils.startOfDay(DateTime.now()),
          selectedCalendarIds: selectedCalendarIds,
        );
      case DeepLinkCreateEventAction():
        await DashboardScreen.openEventFormSheet(
          context,
          initialDay: dashboardState.selectedDate,
          initialTitle: action.title,
          initialStart: action.start,
          initialEnd: action.end,
        );
      case DeepLinkCreateTaskFromTemplateAction(:final Id templateId):
        final UiTemplate? template =
            await context.read<UiTemplateRepository>().getById(templateId);
        if (!mounted || template == null) {
          return;
        }
        await DashboardScreen.openTaskFormSheet(
          context,
          initialDueDate: AppDateUtils.startOfDay(dashboardState.selectedDate),
          selectedCalendarIds: selectedCalendarIds,
          templateToApply: template,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (DashboardState previous, DashboardState current) =>
          current is DashboardLoaded && _pending != null,
      listener: (BuildContext context, DashboardState state) {
        unawaited(_dispatch());
      },
      child: widget.child,
    );
  }
}
