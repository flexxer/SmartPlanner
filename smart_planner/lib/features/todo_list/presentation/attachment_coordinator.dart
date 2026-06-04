import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/calendar_integration/domain/event_attachment_snapshot.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_snapshot.dart';
import 'package:smart_planner/core/presentation/widgets/delete_undo_snackbar.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/add_attachment_sheet.dart';

/// Add / edit / delete attachment flows for tasks and calendar events.
class AttachmentCoordinator {
  AttachmentCoordinator._();

  static Future<void> openAddForTask(
    BuildContext context, {
    required Task task,
  }) async {
    final TaskAttachmentRepository repository =
        context.read<TaskAttachmentRepository>();
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet(
        repository: repository,
        taskId: task.id,
      ),
    );
    if (added == true && context.mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
      _showSnackBar(context, 'snackbar_attachment_added'.tr());
    }
  }

  static Future<void> openEditForTask(
    BuildContext context, {
    required Task task,
    required TaskAttachment attachment,
  }) async {
    final DashboardBloc dashboardBloc = context.read<DashboardBloc>();
    final TaskAttachmentRepository repository =
        context.read<TaskAttachmentRepository>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet(
        repository: repository,
        taskId: task.id,
        attachmentToEdit: attachment,
        dashboardBloc: dashboardBloc,
      ),
    );
    if (saved == true && context.mounted) {
      _showSnackBar(context, 'snackbar_attachment_updated'.tr());
    }
  }

  static void deleteForTaskWithUndo(
    BuildContext context, {
    required TaskAttachment attachment,
  }) {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final TaskAttachment backup = taskAttachmentSnapshot(attachment);
    bloc.add(DeleteTaskAttachment(attachment.id));
    showDeleteUndoSnackBar(
      context,
      messageKey: 'snackbar_attachment_deleted',
      onUndo: () => bloc.add(RestoreTaskAttachment(backup)),
    );
  }

  static Future<void> openAddForEvent(
    BuildContext context, {
    required Id eventId,
    required VoidCallback onChanged,
  }) async {
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet.forEvent(
        repository: repository,
        eventId: eventId,
      ),
    );
    if (added == true && context.mounted) {
      onChanged();
      _showSnackBar(context, 'snackbar_attachment_added'.tr());
    }
  }

  static Future<void> openEditForEvent(
    BuildContext context, {
    required Id eventId,
    required EventAttachment attachment,
    required VoidCallback onChanged,
  }) async {
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet.forEvent(
        repository: repository,
        eventId: eventId,
        attachmentToEdit: attachment,
      ),
    );
    if (saved == true && context.mounted) {
      onChanged();
      _showSnackBar(context, 'snackbar_attachment_updated'.tr());
    }
  }

  static void deleteForEventWithUndo(
    BuildContext context, {
    required EventAttachment attachment,
    required VoidCallback onChanged,
  }) {
    final EventAttachmentRepository repository =
        context.read<EventAttachmentRepository>();
    final EventAttachment backup = eventAttachmentSnapshot(attachment);
    repository.delete(attachment.id).then((_) {
      if (context.mounted) {
        onChanged();
      }
    });
    showDeleteUndoSnackBar(
      context,
      messageKey: 'snackbar_attachment_deleted',
      onUndo: () async {
        await repository.save(backup);
        if (context.mounted) {
          onChanged();
        }
      },
    );
  }

  static Future<void> toggleEventChecklistItem({
    required EventAttachmentRepository repository,
    required Id attachmentId,
    required int itemLocalId,
  }) async {
    final EventAttachment? attachment = await repository.getById(attachmentId);
    if (attachment == null) {
      return;
    }
    if (!TaskAttachmentChecklist.toggleEventItem(attachment, itemLocalId)) {
      return;
    }
    await repository.update(attachment);
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}
