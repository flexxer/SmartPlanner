import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

/// Single entry point for task↔event links and parent↔child attachments.
class TaskEventLinkService {
  TaskEventLinkService({
    required this.localCalendarEvents,
    required this.todoRepository,
  });

  final LocalCalendarEventRepository localCalendarEvents;
  final TodoRepository todoRepository;

  Future<void> linkTaskToEvent({
    required Id taskId,
    required Id eventId,
  }) =>
      localCalendarEvents.linkTask(eventId: eventId, taskId: taskId);

  Future<void> unlinkTaskFromEvent(Id taskId) =>
      localCalendarEvents.unlinkTask(taskId);

  Future<bool> attachTaskToParent({
    required Id childTaskId,
    required Id parentTaskId,
  }) async =>
      (await todoRepository.attachTaskToParent(
        childTaskId: childTaskId,
        parentTaskId: parentTaskId,
      )).getOrElse((_) => false);

  Future<void> detachTaskFromParent(Id childTaskId) =>
      todoRepository.detachTaskFromParent(childTaskId);

  /// Applies optional event link and parent attachment after task create.
  Future<void> applyPostCreateRelations({
    required Id taskId,
    Id? linkedEventId,
    Id? parentTaskId,
  }) async {
    if (linkedEventId != null) {
      await linkTaskToEvent(taskId: taskId, eventId: linkedEventId);
    }
    if (parentTaskId != null) {
      await attachTaskToParent(
        childTaskId: taskId,
        parentTaskId: parentTaskId,
      );
    }
  }
}
