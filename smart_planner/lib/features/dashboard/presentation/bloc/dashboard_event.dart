import 'package:isar/isar.dart';

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

/// Перенос срока на [newDueDate] ([TaskOverdueRules.recordPostpone]).
final class PostponeTask extends DashboardEvent {
  const PostponeTask({
    required this.taskId,
    required this.newDueDate,
  });

  final Id taskId;
  final DateTime newDueDate;
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

/// Переключить пункт в чеклисте-вложении.
final class ToggleAttachmentChecklistItem extends DashboardEvent {
  const ToggleAttachmentChecklistItem({
    required this.attachmentId,
    required this.itemLocalId,
  });

  final Id attachmentId;
  final int itemLocalId;
}
