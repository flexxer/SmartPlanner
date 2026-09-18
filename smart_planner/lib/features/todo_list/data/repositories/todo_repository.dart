import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/data/models/task_model.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/domain/repositories/task_repository.dart';
import 'package:smart_planner/features/todo_list/domain/task_date_visibility.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_rules.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_selection.dart';
import 'package:smart_planner/features/todo_list/domain/task_reopen.dart';

/// CRUD for tasks in the local Isar database. Maps between the pure [Task]
/// domain entity and the [TaskModel] persistence row, and reports failures as
/// [Result].
class TodoRepository implements TaskRepository {
  TodoRepository({
    this.isar,
    TaskAttachmentRepository? attachmentRepository,
  }) : _attachmentRepository =
            attachmentRepository ?? TaskAttachmentRepository(isar: isar);

  final Isar? isar;
  final TaskAttachmentRepository _attachmentRepository;

  Isar get _db => isar ?? IsarDatabase.instance;

  @override
  Future<Result<List<Task>>> getAllTasks() async {
    try {
      final List<TaskModel> models = await _db.taskModels.where().findAll();
      return Success(
        models.map((TaskModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load tasks: $error', stackTrace));
    }
  }

  @override
  Future<Result<Task?>> getTaskById(int id) async {
    try {
      final TaskModel? model = await _db.taskModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load task $id: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<Task>>> getUncompletedTasks() async {
    try {
      final List<TaskModel> models = await _db.taskModels
          .filter()
          .isCompletedEqualTo(false)
          .findAll();
      final List<Task> tasks =
          models.map((TaskModel m) => m.toDomain()).toList(growable: false);
      tasks.sort(compareTasksByPriority);
      return Success(tasks);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load tasks: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<Task>>> getCompletedTasks() async {
    try {
      final List<TaskModel> models = await _db.taskModels
          .filter()
          .isCompletedEqualTo(true)
          .findAll();
      final List<Task> tasks =
          models.map((TaskModel m) => m.toDomain()).toList(growable: false);
      tasks.sort((Task a, Task b) => b.createDate.compareTo(a.createDate));
      return Success(tasks);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load tasks: $error', stackTrace));
    }
  }

  @override
  Future<Result<Task>> reopenFromCompleted(Task source, DateTime newDueDate) async {
    try {
      final Task reopened = TaskReopen.fromCompleted(source, dueDate: newDueDate);
      final Result<Task> saved = await saveTask(reopened);
      final Task savedTask = saved.getOrElse((f) => throw StateError('$f'));
      await _attachmentRepository.copyAttachmentsToTask(
        fromTaskId: source.id,
        toTaskId: savedTask.id,
      );
      return Success(savedTask);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to reopen task: $error', stackTrace));
    }
  }

  /// Rolls overdue root tasks onto [referenceDay] (midnight auto-postpone).
  Future<int> rollOverdueUncompletedToToday({DateTime? referenceDay}) async {
    final DateTime day = AppDateUtils.startOfDay(referenceDay ?? DateTime.now());
    final List<Task> overdue = (await getOverdueUncompletedTasks(referenceDay: day))
        .getOrElse((_) => <Task>[]);
    if (overdue.isEmpty) {
      return 0;
    }
    await _db.writeTxn(() async {
      for (final Task task in overdue) {
        TaskOverdueRules.rollToToday(task, referenceDay: day);
        await _db.taskModels.put(TaskModel.fromDomain(task));
      }
    });
    return overdue.length;
  }

  @override
  Future<Result<List<Task>>> getOverdueUncompletedTasks({
    DateTime? referenceDay,
  }) async {
    final DateTime day = AppDateUtils.startOfDay(referenceDay ?? DateTime.now());
    final Result<List<Task>> result = await getUncompletedTasks();
    return result.map(
      (List<Task> tasks) => TaskOverdueSelection.filterOverdueTasks(
        tasks.where(TaskHierarchy.isRoot),
        day,
      ),
    );
  }

  @override
  Future<Result<List<Task>>> getUncompletedTasksForDate(DateTime date) async {
    final Result<List<Task>> result = await getUncompletedTasks();
    final DateTime day = AppDateUtils.startOfDay(date);
    return result.map(
      (List<Task> tasks) => tasks
          .where(
            (Task t) =>
                TaskHierarchy.isRoot(t) &&
                t.dueDate != null &&
                TaskDateVisibility.isVisibleOnDate(t, day),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Task>>> getUndatedTasks() async {
    final Result<List<Task>> result = await getUncompletedTasks();
    return result.map(
      (List<Task> tasks) => tasks
          .where((Task t) => TaskHierarchy.isRoot(t) && t.dueDate == null)
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Task>>> getCompletedTasksForDate(DateTime date) async {
    final Result<List<Task>> result = await getCompletedTasks();
    final DateTime day = AppDateUtils.startOfDay(date);
    return result.map(
      (List<Task> tasks) => tasks
          .where(
            (Task t) =>
                TaskHierarchy.isRoot(t) &&
                TaskDateVisibility.isCompletedVisibleOnDate(t, day),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Task>>> getAllChildTasks(int parentTaskId) async {
    try {
      final List<TaskModel> models = await _db.taskModels
          .filter()
          .parentTaskIdEqualTo(parentTaskId)
          .findAll();
      return Success(
        models.map((TaskModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load child tasks: $error', stackTrace));
    }
  }

  @override
  Future<Result<ChildTasksBundle>> getChildTasksBundle(int parentTaskId) async {
    final Result<List<Task>> result = await getAllChildTasks(parentTaskId);
    return result.map((List<Task> allChildren) {
      final List<Task> activeChildren =
          allChildren.where((Task t) => !t.isCompleted).toList(growable: false);
      activeChildren.sort(compareChildTasks);
      final int completedCount =
          allChildren.where((Task t) => t.isCompleted).length;
      return ChildTasksBundle(
        activeChildren: activeChildren,
        completedCount: completedCount,
        totalCount: allChildren.length,
      );
    });
  }

  @override
  Future<Result<Map<int, ChildTasksBundle>>> getChildTasksBundlesForParents(
    List<int> parentIds,
  ) async {
    try {
      final Map<int, ChildTasksBundle> result = <int, ChildTasksBundle>{};
      for (final int parentId in parentIds) {
        result[parentId] =
            (await getChildTasksBundle(parentId)).getOrElse((_) => const ChildTasksBundle(
                activeChildren: <Task>[], completedCount: 0, totalCount: 0));
      }
      return Success(result);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load child bundles: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<Task>>> getTasksAttachableToEvent(CalendarEvent event) async {
    final Set<int> linkedIds = event.linkedTaskIds.toSet();
    final Result<List<Task>> result = await getUncompletedTasks();
    return result.map((List<Task> all) {
      final List<Task> attachable =
          all.where((Task t) => !linkedIds.contains(t.id)).toList(growable: false);
      attachable.sort(compareTasksByPriority);
      return attachable;
    });
  }

  @override
  Future<Result<List<Task>>> getTasksAttachableToParent(int parentTaskId) async {
    final Result<List<Task>> result = await getUncompletedTasks();
    return result.map((List<Task> all) {
      final List<Task> attachable = all
          .where(
            (Task t) => TaskHierarchy.isAttachableCandidate(t, parentTaskId, all),
          )
          .toList(growable: false);
      attachable.sort(compareTasksByPriority);
      return attachable;
    });
  }

  @override
  Future<Result<bool>> attachTaskToParent({
    required int childTaskId,
    required int parentTaskId,
  }) async {
    try {
      final Task? child = (await getTaskById(childTaskId)).getOrElse((_) => null);
      if (child == null) {
        return Success(false);
      }
      final List<Task> all =
          (await getUncompletedTasks()).getOrElse((_) => <Task>[]);
      if (!TaskHierarchy.attach(child: child, parentId: parentTaskId, allTasks: all)) {
        return Success(false);
      }
      child.sortOrder = await _nextChildSortOrder(parentTaskId);
      await updateTask(child);
      return Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to attach task: $error', stackTrace));
    }
  }

  /// Persists manual child order under [parentTaskId] ([Task.sortOrder] = list index).
  @override
  Future<Result<bool>> reorderChildTasks({
    required int parentTaskId,
    required List<int> orderedChildIds,
  }) async {
    try {
      await _db.writeTxn(() async {
        for (int index = 0; index < orderedChildIds.length; index++) {
          final TaskModel? child = await _db.taskModels.get(orderedChildIds[index]);
          if (child == null || child.parentTaskId != parentTaskId) {
            continue;
          }
          child.sortOrder = index;
          child.updatedAt = DateTime.now();
          await _db.taskModels.put(child);
        }
      });
      return Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to reorder tasks: $error', stackTrace));
    }
  }

  Future<int> _nextChildSortOrder(int parentTaskId) async {
    final List<Task> siblings =
        (await getAllChildTasks(parentTaskId)).getOrElse((_) => <Task>[]);
    if (siblings.isEmpty) {
      return 0;
    }
    int maxOrder = siblings.first.sortOrder;
    for (final Task sibling in siblings) {
      if (sibling.sortOrder > maxOrder) {
        maxOrder = sibling.sortOrder;
      }
    }
    return maxOrder + 1;
  }

  @override
  Future<Result<bool>> detachTaskFromParent(int childTaskId) async {
    try {
      final Task? child = (await getTaskById(childTaskId)).getOrElse((_) => null);
      if (child == null) {
        return Success(false);
      }
      TaskHierarchy.detach(child);
      await updateTask(child);
      return Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to detach task: $error', stackTrace));
    }
  }

  @override
  Future<Result<Task>> saveTask(Task task) async {
    try {
      task.markUpdated();
      final TaskModel model = TaskModel.fromDomain(task);
      final int newId = await _db.writeTxn(() => _db.taskModels.put(model));
      task.id = newId;
      return Success(task);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to save task: $error', stackTrace));
    }
  }

  @override
  Future<Result<Task>> updateTask(Task task) async {
    try {
      task.markUpdated();
      final TaskModel model = TaskModel.fromDomain(task);
      await _db.writeTxn(() => _db.taskModels.put(model));
      return Success(task);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to update task: $error', stackTrace));
    }
  }

  @override
  Future<Result<bool>> deleteTask(int id) async {
    try {
      final bool deleted = await _db.writeTxn(() => _db.taskModels.delete(id));
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to delete task: $error', stackTrace));
    }
  }

  /// Sort key for sibling tasks under one parent ([Task.sortOrder] first).
  static int compareChildTasks(Task a, Task b) {
    final int byOrder = a.sortOrder.compareTo(b.sortOrder);
    if (byOrder != 0) {
      return byOrder;
    }
    return compareTasksByPriority(a, b);
  }

  static int compareTasksByPriority(Task a, Task b) {
    final int byPriority =
        b.priority.sortWeight.compareTo(a.priority.sortWeight);
    if (byPriority != 0) {
      return byPriority;
    }

    final int byOverdue =
        b.dynamicOverdueDays.compareTo(a.dynamicOverdueDays);
    if (byOverdue != 0) {
      return byOverdue;
    }

    final DateTime? dueA = a.dueDate;
    final DateTime? dueB = b.dueDate;
    if (dueA == null && dueB == null) {
      return 0;
    }
    if (dueA == null) {
      return 1;
    }
    if (dueB == null) {
      return -1;
    }
    return dueA.compareTo(dueB);
  }
}
