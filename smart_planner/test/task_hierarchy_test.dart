import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

void main() {
  Task task({required int id, int? parentId, String title = 'T'}) {
    final Task t = Task.create(title: title);
    t.id = id;
    t.parentTaskId = parentId;
    return t;
  }

  test('attach and detach', () {
    final Task parent = task(id: 1, title: 'Parent');
    final Task child = task(id: 2, title: 'Child');
    final List<Task> all = <Task>[parent, child];

    expect(
      TaskHierarchy.attach(child: child, parentId: 1, allTasks: all),
      isTrue,
    );
    expect(child.parentTaskId, 1);

    TaskHierarchy.detach(child);
    expect(child.parentTaskId, isNull);
  });

  test('prevents cycles', () {
    final Task a = task(id: 1);
    final Task b = task(id: 2, parentId: 1);
    final Task c = task(id: 3, parentId: 2);
    final List<Task> all = <Task>[a, b, c];

    expect(
      TaskHierarchy.canAttach(child: a, parentId: 3, allTasks: all),
      isFalse,
    );
  });

  test('excludedDescendantIds includes parent and children', () {
    final List<Task> all = <Task>[
      task(id: 1),
      task(id: 2, parentId: 1),
      task(id: 3, parentId: 2),
    ];
    expect(TaskHierarchy.excludedDescendantIds(1, all), <int>{1, 2, 3});
  });
}
