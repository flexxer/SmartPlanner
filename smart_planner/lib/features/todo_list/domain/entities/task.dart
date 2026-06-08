import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/domain/task_overdue_rules.dart';

part 'task.g.dart';

/// To-Do task (PRD §3.2).
///
/// Context list is [calendarId] (device calendar from app settings).
/// Overdue duration is computed via [dynamicOverdueDays], not stored in Isar.
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

  @Enumerated(EnumType.ordinal)
  @Index()
  TaskPriority priority = TaskPriority.medium;

  /// When set, this task is a subtask of another [Task] and is hidden from the root dashboard list.
  @Index()
  int? parentTaskId;

  /// Order among siblings sharing the same [parentTaskId] (lower = higher in lists).
  int sortOrder = 0;

  /// Device calendar id (context list: Work, Personal, etc.).
  @Index()
  late String calendarId;

  /// Future Google Tasks sync id.
  String? googleTaskId;

  /// Google Tasks list id when synced via API (distinct from [calendarId]).
  String? googleTaskListId;

  /// Local [CalendarEvent.id] when the task belongs to a meeting or recurrence instance.
  @Index()
  int? linkedEventId;

  /// Last mutation time for future sync conflict resolution.
  DateTime? updatedAt;

  /// When to fire a local reminder; `null` = no reminder.
  DateTime? reminderAt;

  /// JSON [RecurrenceRule] for repeating tasks (same format as calendar events).
  String? recurrenceRuleJson;

  Task();

  Task.create({
    required this.title,
    this.description,
    this.dueDate,
    DateTime? createDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.parentTaskId,
    this.sortOrder = 0,
    this.calendarId = '',
    this.googleTaskId,
    this.googleTaskListId,
    this.linkedEventId,
    this.reminderAt,
  }) : createDate = createDate ?? DateTime.now() {
    markUpdated();
  }

  @ignore
  RecurrenceRule? get recurrenceRule {
    final String? json = recurrenceRuleJson;
    if (json == null || json.isEmpty) {
      return null;
    }
    return RecurrenceRule.fromJsonString(json);
  }

  @ignore
  set recurrenceRule(RecurrenceRule? rule) {
    recurrenceRuleJson = rule?.toJsonString();
  }

  /// Calendar days past [dueDate] relative to now (see [TaskOverdueRules]).
  @ignore
  int get dynamicOverdueDays => TaskOverdueRules.dynamicOverdueDays(this);

  /// Sets [updatedAt] to now. Call after in-memory field changes before persisting.
  void markUpdated() {
    updatedAt = DateTime.now();
  }

  /// Moves the due date; overdue duration is recalculated automatically.
  void postponeDueDate(DateTime newDueDate) {
    TaskOverdueRules.recordPostpone(this, newDueDate);
  }

  /// Postpones to the next calendar day after [referenceDate].
  void postponeToNextDay({DateTime? referenceDate}) {
    TaskOverdueRules.postponeToNextDay(this, referenceDate: referenceDate);
  }
}
