import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/deleted_calendar_event_snapshot.dart';
import 'package:smart_planner/features/todo_list/domain/deleted_task_snapshot.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
sealed class DashboardEvent {
  const DashboardEvent();
}

/// Загрузка задач на [selectedDate] и событий календаря за этот день.
final class LoadDashboardData extends DashboardEvent {
  const LoadDashboardData({
    this.selectedCalendarIds,
    this.selectedDate,
  });

  /// ID календарей для выборки. `null` или пусто — все доступные календари.
  final List<String>? selectedCalendarIds;

  /// Календарный день; `null` — сохранить текущий в BLoC или взять сегодня.
  final DateTime? selectedDate;
}

/// Смена дня на дашборде (задачи и события перезагружаются).
final class SelectDashboardDate extends DashboardEvent {
  const SelectDashboardDate(this.date);

  final DateTime date;
}

/// Быстрое переключение [Task.isCompleted] с обновлением списка на дашборде.
final class ToggleTaskCompletion extends DashboardEvent {
  const ToggleTaskCompletion(this.taskId);

  final Id taskId;
}

/// Перенос срока на следующий день от [referenceDate] в [DashboardLoaded].
final class PostponeTaskToNextDay extends DashboardEvent {
  const PostponeTaskToNextDay(this.taskId);

  final Id taskId;
}

/// Перенос срока на [newDueDate] (обновляет [Task.dueDate]).
final class PostponeTask extends DashboardEvent {
  const PostponeTask({
    required this.taskId,
    required this.newDueDate,
  });

  final Id taskId;
  final DateTime newDueDate;
}

/// Update [Task.sortOrder] for children under [parentTaskId].
final class ReorderChildTasks extends DashboardEvent {
  const ReorderChildTasks({
    required this.parentTaskId,
    required this.orderedChildIds,
  });

  final Id parentTaskId;
  final List<Id> orderedChildIds;
}

/// Привязать существующую задачу как подзадачу.
final class LinkTaskAsChild extends DashboardEvent {
  const LinkTaskAsChild({
    required this.parentTaskId,
    required this.childTaskId,
  });

  final Id parentTaskId;
  final Id childTaskId;
}

/// Отвязать задачу от родителя (снова в корневом списке).
final class DetachTaskFromParent extends DashboardEvent {
  const DetachTaskFromParent(this.childTaskId);

  final Id childTaskId;
}

/// Удалить [TaskAttachment].
final class DeleteTaskAttachment extends DashboardEvent {
  const DeleteTaskAttachment(this.attachmentId);

  final Id attachmentId;
}

/// Восстановить [TaskAttachment] после отмены удаления (Undo).
final class RestoreTaskAttachment extends DashboardEvent {
  const RestoreTaskAttachment(this.attachment);

  final TaskAttachment attachment;
}

/// Сохранить изменения вложения и обновить дашборд.
final class UpdateTaskAttachment extends DashboardEvent {
  const UpdateTaskAttachment(this.attachment);

  final TaskAttachment attachment;
}

/// Link a task to a local [CalendarEvent] (Isar).
final class LinkTaskToCalendarEvent extends DashboardEvent {
  const LinkTaskToCalendarEvent({
    required this.taskId,
    required this.eventId,
  });

  final Id taskId;
  final Id eventId;
}

/// Remove task↔event link.
final class UnlinkTaskFromCalendarEvent extends DashboardEvent {
  const UnlinkTaskFromCalendarEvent(this.taskId);

  final Id taskId;
}

/// Переключить пункт в чеклисте-вложении.
final class ToggleAttachmentChecklistItem extends DashboardEvent {
  const ToggleAttachmentChecklistItem({
    required this.attachmentId,
    required this.itemLocalId,
  });

  final Id attachmentId;
  final int itemLocalId;
}

/// Persist edited task fields and refresh the dashboard list.
final class UpdateTask extends DashboardEvent {
  const UpdateTask(this.task);

  final Task task;
}

/// Remove a task from Isar and refresh the dashboard.
final class DeleteTask extends DashboardEvent {
  const DeleteTask(this.taskId);

  final Id taskId;
}

/// Remove a local calendar event from Isar and refresh the dashboard.
final class DeleteCalendarEvent extends DashboardEvent {
  const DeleteCalendarEvent(
    this.eventId, {
    this.thisInstanceOnly = false,
  });

  final Id eventId;
  final bool thisInstanceOnly;
}

/// Restore a task deleted within the undo window.
final class RestoreDeletedTask extends DashboardEvent {
  const RestoreDeletedTask(this.snapshot);

  final DeletedTaskSnapshot snapshot;
}

/// Restore a calendar event deleted within the undo window.
final class RestoreDeletedCalendarEvent extends DashboardEvent {
  const RestoreDeletedCalendarEvent(this.snapshot);

  final DeletedCalendarEventSnapshot snapshot;
}

/// Expand a task tile on the dashboard (e.g. after navigating from a sheet).
final class ExpandDashboardTask extends DashboardEvent {
  const ExpandDashboardTask(this.taskId);

  final Id taskId;
}

/// Clear forced expansion after the tile has opened.
final class ClearExpandedDashboardTask extends DashboardEvent {
  const ClearExpandedDashboardTask();
}
