import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
/// Создание новой задачи на основе выполненной (без изменения оригинала).
class TaskReopen {
  TaskReopen._();

  static Task fromCompleted(Task source, {DateTime? dueDate}) {
    return Task.create(
      title: source.title,
      description: source.description,
      dueDate: dueDate == null ? null : AppDateUtils.startOfDay(dueDate),
      priority: source.priority,
      parentTaskId: null,
    );
  }
}
