import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Parent–child links between [Task] records ([Task.parentTaskId]).
class TaskHierarchy {
  TaskHierarchy._();

  static bool isRoot(Task task) => task.parentTaskId == null;

  /// Task id, all descendant ids, used to prevent cycles when linking.
  static Set<Id> excludedDescendantIds(Id rootId, List<Task> allTasks) {
    final Set<Id> excluded = <Id>{rootId};
    bool changed = true;
    while (changed) {
      changed = false;
      for (final Task task in allTasks) {
        final Id? parentId = task.parentTaskId;
        if (parentId != null &&
            excluded.contains(parentId) &&
            excluded.add(task.id)) {
          changed = true;
        }
      }
    }
    return excluded;
  }

  /// Whether [child] can be attached under [parentId] without cycles or double parenting.
  static bool canAttach({
    required Task child,
    required Id parentId,
    required List<Task> allTasks,
  }) {
    if (child.id == parentId) {
      return false;
    }
    if (child.parentTaskId != null && child.parentTaskId != parentId) {
      return false;
    }
    if (excludedDescendantIds(child.id, allTasks).contains(parentId)) {
      return false;
    }
    return true;
  }

  /// Root tasks that may be linked under [parentTaskId].
  static bool isAttachableCandidate(
    Task candidate,
    Id parentTaskId,
    List<Task> allTasks,
  ) {
    return canAttach(
      child: candidate,
      parentId: parentTaskId,
      allTasks: allTasks,
    );
  }

  static bool attach({
    required Task child,
    required Id parentId,
    required List<Task> allTasks,
  }) {
    if (!canAttach(child: child, parentId: parentId, allTasks: allTasks)) {
      return false;
    }
    child.parentTaskId = parentId;
    return true;
  }

  static void detach(Task child) {
    child.parentTaskId = null;
  }
}

/// Active child tasks plus completion counts (includes completed children).
class ChildTasksBundle {
  const ChildTasksBundle({
    required this.activeChildren,
    required this.completedCount,
    required this.totalCount,
  });

  final List<Task> activeChildren;
  final int completedCount;
  final int totalCount;

  bool get hasChildren => totalCount > 0;

  bool get allCompleted => totalCount > 0 && completedCount == totalCount;
}

/// Progress label for parent task badges (e.g. `2/5` subtasks done).
String? childTaskProgressBadgeLabel(ChildTasksBundle? bundle) {
  if (bundle == null || !bundle.hasChildren) {
    return null;
  }
  return '${bundle.completedCount}/${bundle.totalCount}';
}
