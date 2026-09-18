import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

part 'task_model.g.dart';

/// Isar persistence model for [Task].
@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  String? description;

  bool isCompleted = false;

  @Index()
  DateTime? dueDate;

  @Index()
  late DateTime createDate;

  @Enumerated(EnumType.ordinal)
  @Index()
  TaskPriority priority = TaskPriority.medium;

  @Index()
  int? parentTaskId;

  int sortOrder = 0;

  @Index()
  late String calendarId;

  String? googleTaskId;

  String? googleTaskListId;

  @Index()
  int? linkedEventId;

  DateTime? updatedAt;

  DateTime? reminderAt;

  String? recurrenceRuleJson;

  Task toDomain() => Task(id: id)
    ..title = title
    ..description = description
    ..isCompleted = isCompleted
    ..dueDate = dueDate
    ..createDate = createDate
    ..priority = priority
    ..parentTaskId = parentTaskId
    ..sortOrder = sortOrder
    ..calendarId = calendarId
    ..googleTaskId = googleTaskId
    ..googleTaskListId = googleTaskListId
    ..linkedEventId = linkedEventId
    ..updatedAt = updatedAt
    ..reminderAt = reminderAt
    ..recurrenceRuleJson = recurrenceRuleJson;

  static TaskModel fromDomain(Task task) {
    final TaskModel model = TaskModel()
      ..title = task.title
      ..description = task.description
      ..isCompleted = task.isCompleted
      ..dueDate = task.dueDate
      ..createDate = task.createDate
      ..priority = task.priority
      ..parentTaskId = task.parentTaskId
      ..sortOrder = task.sortOrder
      ..calendarId = task.calendarId
      ..googleTaskId = task.googleTaskId
      ..googleTaskListId = task.googleTaskListId
      ..linkedEventId = task.linkedEventId
      ..updatedAt = task.updatedAt
      ..reminderAt = task.reminderAt
      ..recurrenceRuleJson = task.recurrenceRuleJson;
    if (task.id > 0) {
      model.id = task.id;
    }
    return model;
  }
}
