import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_category.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/domain/task_date_visibility.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_selection.dart';
import 'package:smart_planner/features/todo_list/domain/task_reopen.dart';

/// CRUD задач и категорий в локальной БД Isar.
class TodoRepository {
  TodoRepository({
    this._isar,
    TaskAttachmentRepository? attachmentRepository,
  }) : _attachmentRepository =
            attachmentRepository ?? TaskAttachmentRepository(isar: _isar);

  final Isar? _isar;
  final TaskAttachmentRepository _attachmentRepository;

  Isar get _db => _isar ?? IsarDatabase.instance;

  // ——— Tasks ———

  Future<List<Task>> getAllTasks() => _db.tasks.where().findAll();

  Future<Task?> getTaskById(Id id) => _db.tasks.get(id);

  /// Невыполненные задачи: сначала выше [Task.priority], затем [Task.overdueCount],
  /// затем ближайший [Task.dueDate] (без срока — в конце).
  Future<List<Task>> getUncompletedTasks() async {
    final List<Task> tasks = await _db.tasks
        .filter()
        .isCompletedEqualTo(false)
        .findAll();

    tasks.sort(_compareTasksByPriority);
    return tasks;
  }

  /// Выполненные задачи, новые сверху по [Task.createDate].
  Future<List<Task>> getCompletedTasks() async {
    final List<Task> tasks = await _db.tasks
        .filter()
        .isCompletedEqualTo(true)
        .findAll();

    tasks.sort(
      (Task a, Task b) => b.createDate.compareTo(a.createDate),
    );
    return tasks;
  }

  /// Копия выполненной задачи с новым сроком; исходная остаётся выполненной.
  Future<Task> reopenFromCompleted(Task source, DateTime newDueDate) async {
    await loadTaskCategory(source);
    final TaskCategory? category = source.category.value;
    final Task reopened = TaskReopen.fromCompleted(
      source,
      dueDate: newDueDate,
    );
    await saveTask(reopened, category: category);
    await _attachmentRepository.copyAttachmentsToTask(
      fromTaskId: source.id,
      toTaskId: reopened.id,
    );
    return reopened;
  }

  /// Root uncompleted tasks whose [Task.dueDate] is strictly before [referenceDay].
  Future<List<Task>> getOverdueUncompletedTasks({
    DateTime? referenceDay,
  }) async {
    final DateTime day =
        AppDateUtils.startOfDay(referenceDay ?? DateTime.now());
    final List<Task> tasks = await getUncompletedTasks();
    return TaskOverdueSelection.filterOverdueTasks(
      tasks.where(TaskHierarchy.isRoot),
      day,
    );
  }

  /// Невыполненные задачи на календарный день [date] (включая перенесённые просроченные).
  Future<List<Task>> getUncompletedTasksForDate(DateTime date) async {
    final List<Task> tasks = await getUncompletedTasks();
    final DateTime day = AppDateUtils.startOfDay(date);
    return tasks
        .where(
          (Task t) =>
              TaskHierarchy.isRoot(t) &&
              TaskDateVisibility.isVisibleOnDate(t, day),
        )
        .toList(growable: false);
  }

  /// All tasks with [parentTaskId] (active + completed).
  Future<List<Task>> getAllChildTasks(Id parentTaskId) => _db.tasks
      .filter()
      .parentTaskIdEqualTo(parentTaskId)
      .findAll();

  Future<ChildTasksBundle> getChildTasksBundle(Id parentTaskId) async {
    final List<Task> allChildren = await getAllChildTasks(parentTaskId);
    final List<Task> activeChildren = allChildren
        .where((Task t) => !t.isCompleted)
        .toList(growable: false);
    activeChildren.sort(_compareTasksByPriority);
    final int completedCount =
        allChildren.where((Task t) => t.isCompleted).length;
    return ChildTasksBundle(
      activeChildren: activeChildren,
      completedCount: completedCount,
      totalCount: allChildren.length,
    );
  }

  Future<Map<Id, ChildTasksBundle>> getChildTasksBundlesForParents(
    List<Id> parentIds,
  ) async {
    final Map<Id, ChildTasksBundle> result = <Id, ChildTasksBundle>{};
    for (final Id parentId in parentIds) {
      result[parentId] = await getChildTasksBundle(parentId);
    }
    return result;
  }

  /// Root uncompleted tasks that may be linked under [parentTaskId].
  Future<List<Task>> getTasksAttachableToParent(Id parentTaskId) async {
    final List<Task> all = await getUncompletedTasks();
    final List<Task> attachable = all
        .where(
          (Task t) => TaskHierarchy.isAttachableCandidate(
            t,
            parentTaskId,
            all,
          ),
        )
        .toList(growable: false);
    attachable.sort(_compareTasksByPriority);
    return attachable;
  }

  Future<bool> attachTaskToParent({
    required Id childTaskId,
    required Id parentTaskId,
  }) async {
    final Task? child = await getTaskById(childTaskId);
    if (child == null) {
      return false;
    }
    final List<Task> all = await getUncompletedTasks();
    if (!TaskHierarchy.attach(
      child: child,
      parentId: parentTaskId,
      allTasks: all,
    )) {
      return false;
    }
    await updateTask(child);
    return true;
  }

  Future<void> detachTaskFromParent(Id childTaskId) async {
    final Task? child = await getTaskById(childTaskId);
    if (child == null) {
      return;
    }
    TaskHierarchy.detach(child);
    await updateTask(child);
  }

  Future<Id> saveTask(Task task, {TaskCategory? category}) async {
    return _db.writeTxn(() async {
      final Id id = await _db.tasks.put(task);
      if (category != null) {
        task.category.value = category;
        await task.category.save();
      }
      return id;
    });
  }

  Future<void> updateTask(Task task, {TaskCategory? category}) async {
    await _db.writeTxn(() async {
      await _db.tasks.put(task);
      if (category != null) {
        task.category.value = category;
        await task.category.save();
      }
    });
  }

  Future<bool> deleteTask(Id id) =>
      _db.writeTxn(() => _db.tasks.delete(id));

  Future<void> loadTaskCategory(Task task) => task.category.load();

  // ——— Categories ———

  Future<List<TaskCategory>> getAllCategories() =>
      _db.taskCategorys.where().sortByName().findAll();

  Future<TaskCategory?> getCategoryById(Id id) => _db.taskCategorys.get(id);

  Future<Id> saveCategory(TaskCategory category) =>
      _db.writeTxn(() => _db.taskCategorys.put(category));

  Future<void> updateCategory(TaskCategory category) async {
    await _db.writeTxn(() => _db.taskCategorys.put(category));
  }

  Future<bool> deleteCategory(Id id) =>
      _db.writeTxn(() => _db.taskCategorys.delete(id));

  static int _compareTasksByPriority(Task a, Task b) {
    final int byPriority =
        b.priority.sortWeight.compareTo(a.priority.sortWeight);
    if (byPriority != 0) {
      return byPriority;
    }

    final int byOverdue = b.overdueCount.compareTo(a.overdueCount);
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
