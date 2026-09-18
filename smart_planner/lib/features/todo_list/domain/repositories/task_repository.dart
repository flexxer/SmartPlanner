import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Domain contract for task persistence (implemented by [TodoRepository]).
abstract class TaskRepository {
  Future<Result<List<Task>>> getAllTasks();

  Future<Result<Task?>> getTaskById(int id);

  Future<Result<List<Task>>> getUncompletedTasks();

  Future<Result<List<Task>>> getCompletedTasks();

  Future<Result<Task>> reopenFromCompleted(Task source, DateTime newDueDate);

  Future<Result<List<Task>>> getOverdueUncompletedTasks({DateTime? referenceDay});

  Future<Result<List<Task>>> getUncompletedTasksForDate(DateTime date);

  Future<Result<List<Task>>> getUndatedTasks();

  Future<Result<List<Task>>> getCompletedTasksForDate(DateTime date);

  Future<Result<List<Task>>> getAllChildTasks(int parentTaskId);

  Future<Result<ChildTasksBundle>> getChildTasksBundle(int parentTaskId);

  Future<Result<Map<int, ChildTasksBundle>>> getChildTasksBundlesForParents(
    List<int> parentTaskIds,
  );

  Future<Result<List<Task>>> getTasksAttachableToEvent(CalendarEvent event);

  Future<Result<List<Task>>> getTasksAttachableToParent(int parentTaskId);

  Future<Result<bool>> attachTaskToParent({
    required int childTaskId,
    required int parentTaskId,
  });

  Future<Result<bool>> reorderChildTasks({
    required int parentTaskId,
    required List<int> orderedChildIds,
  });

  Future<Result<bool>> detachTaskFromParent(int childTaskId);

  Future<Result<Task>> saveTask(Task task);

  Future<Result<Task>> updateTask(Task task);

  Future<Result<bool>> deleteTask(int id);
}
