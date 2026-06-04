import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/presentation/widgets/delete_undo_snackbar.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_recurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/deleted_calendar_event_snapshot.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/calendar_event_delete_dialog.dart';
import 'package:smart_planner/features/todo_list/domain/deleted_task_snapshot.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_calendar_mutations.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_task_mutations.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';

/// Task/event delete with 10s undo snackbar.
class RecordDeleteCoordinator {
  RecordDeleteCoordinator._();

  static Future<void> deleteTask(
    BuildContext context, {
    required Task task,
    required DashboardBloc bloc,
    VoidCallback? onDeleted,
  }) async {
    final DashboardTaskMutations mutations =
        DashboardTaskMutations(bloc.dependencies);
    final DeletedTaskSnapshot? snapshot =
        await mutations.captureTaskForDelete(task.id);
    if (snapshot == null || !context.mounted) {
      return;
    }

    bloc.add(DeleteTask(task.id));
    onDeleted?.call();

    if (!context.mounted) {
      return;
    }
    showDeleteUndoSnackBar(
      context,
      messageKey: 'snackbar_task_deleted',
      onUndo: () => bloc.add(RestoreDeletedTask(snapshot)),
    );
  }

  static Future<void> deleteCalendarEvent(
    BuildContext context, {
    required CalendarEvent event,
    required DashboardBloc bloc,
    VoidCallback? onDeleted,
  }) async {
    var thisInstanceOnly = false;
    if (CalendarEventRecurrence.hasRepeatingRule(event)) {
      final CalendarEventDeleteScope? scope =
          await showCalendarEventDeleteDialog(context);
      if (!context.mounted || scope == null) {
        return;
      }
      thisInstanceOnly = scope == CalendarEventDeleteScope.thisInstance;
    }

    final DashboardCalendarMutations mutations =
        DashboardCalendarMutations(bloc.dependencies);
    final DeletedCalendarEventSnapshot? snapshot =
        await mutations.captureEventForDelete(
      event.id,
      thisInstanceOnly: thisInstanceOnly,
    );
    if (snapshot == null || !context.mounted) {
      return;
    }

    bloc.add(
      DeleteCalendarEvent(event.id, thisInstanceOnly: thisInstanceOnly),
    );
    onDeleted?.call();

    if (!context.mounted) {
      return;
    }
    showDeleteUndoSnackBar(
      context,
      messageKey: 'snackbar_event_deleted',
      onUndo: () => bloc.add(RestoreDeletedCalendarEvent(snapshot)),
    );
  }
}
