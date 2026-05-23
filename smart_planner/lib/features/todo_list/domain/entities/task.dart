import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_category.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_rules.dart';

part 'task.g.dart';

/// Задача To-Do Engine (PRD §3.2).
///
/// [overdueCount] — накопительное число календарных дней переноса срока;
/// обновляется через [postponeDueDate] / [TaskOverdueRules].
@collection
class Task {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  String? description;

  bool isCompleted = false;

  @Index()
  DateTime? dueDate;

  @Index()
  late DateTime createDate;

  /// Сколько календарных дней задача переносилась с предыдущего срока.
  int overdueCount = 0;

  @Enumerated(EnumType.ordinal)
  @Index()
  TaskPriority priority = TaskPriority.medium;

  final IsarLink<TaskCategory> category = IsarLink<TaskCategory>();

  /// When set, this task is a subtask of another [Task] and is hidden from the root dashboard list.
  @Index()
  int? parentTaskId;

  Task();

  Task.create({
    required this.title,
    this.description,
    this.dueDate,
    DateTime? createDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.parentTaskId,
  }) : createDate = createDate ?? DateTime.now();

  /// Переносит срок и увеличивает [overdueCount] на разницу в календарных днях.
  void postponeDueDate(DateTime newDueDate) {
    TaskOverdueRules.recordPostpone(this, newDueDate);
  }

  /// Перенос на следующий календарный день (+1 день к [overdueCount] при наличии срока).
  void postponeToNextDay({DateTime? referenceDate}) {
    TaskOverdueRules.postponeToNextDay(this, referenceDate: referenceDate);
  }
}
