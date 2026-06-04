import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Domain contract for task persistence (implemented by [TodoRepository]).
abstract class TaskRepository {
  Future<List<Task>> getAllTasks();

  Future<Task?> getTaskById(Id id);

  Future<List<Task>> getUncompletedTasks();

  Future<List<Task>> getCompletedTasks();

  Future<Task> reopenFromCompleted(Task source, DateTime newDueDate);

  Future<List<Task>> getOverdueUncompletedTasks({DateTime? referenceDay});

  Future<List<Task>> getUncompletedTasksForDate(DateTime date);

  Future<List<Task>> getUndatedTasks();

  Future<List<Task>> getCompletedTasksForDate(DateTime date);

  Future<List<Task>> getAllChildTasks(Id parentTaskId);

  Future<ChildTasksBundle> getChildTasksBundle(Id parentTaskId);

  Future<Map<Id, ChildTasksBundle>> getChildTasksBundlesForParents(
    List<Id> parentTaskIds,
  );

  Future<List<Task>> getTasksAttachableToEvent(CalendarEvent event);

  Future<List<Task>> getTasksAttachableToParent(Id parentTaskId);

  Future<bool> attachTaskToParent({
    required Id childTaskId,
    required Id parentTaskId,
  });

  Future<void> reorderChildTasks({
    required Id parentTaskId,
    required List<Id> orderedChildIds,
  });

  Future<void> detachTaskFromParent(Id childTaskId);

  Future<Id> saveTask(Task task);

  Future<void> updateTask(Task task);

  Future<bool> deleteTask(Id id);
}
