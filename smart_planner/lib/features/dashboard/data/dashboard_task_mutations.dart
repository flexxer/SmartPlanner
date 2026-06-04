import 'package:isar/isar.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_dependencies.dart';
import 'package:smart_planner/features/todo_list/domain/deleted_task_snapshot.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_snapshot.dart';

/// Task, attachment, and link mutations used by [DashboardBloc].
class DashboardTaskMutations {
  DashboardTaskMutations(this._deps);

  final DashboardDependencies _deps;

  Future<Task?> toggleCompletion(Id taskId) async {
    final Task? task = await _deps.todoRepository.getTaskById(taskId);
    if (task == null) {
      return null;
    }
    task.isCompleted = !task.isCompleted;
    await _deps.todoRepository.updateTask(task);
    await _deps.reminderSync.syncTask(task);
    return task;
  }

  Future<bool> postponeToNextDay({
    required Id taskId,
    required DateTime referenceDate,
  }) async {
    final Task? task = await _deps.todoRepository.getTaskById(taskId);
    if (task == null || task.isCompleted) {
      return false;
    }
    task.postponeToNextDay(referenceDate: referenceDate);
    await _deps.todoRepository.updateTask(task);
    await _deps.reminderSync.syncTask(task);
    return true;
  }

  Future<bool> postpone({
    required Id taskId,
    required DateTime newDueDate,
  }) async {
    final Task? task = await _deps.todoRepository.getTaskById(taskId);
    if (task == null || task.isCompleted) {
      return false;
    }
    task.postponeDueDate(newDueDate);
    await _deps.todoRepository.updateTask(task);
    await _deps.reminderSync.syncTask(task);
    return true;
  }

  Future<void> reorderChildTasks({
    required Id parentTaskId,
    required List<Id> orderedChildIds,
  }) =>
      _deps.todoRepository.reorderChildTasks(
        parentTaskId: parentTaskId,
        orderedChildIds: orderedChildIds,
      );

  Future<bool> linkAsChild({
    required Id childTaskId,
    required Id parentTaskId,
  }) =>
      _deps.taskEventLinks.attachTaskToParent(
        childTaskId: childTaskId,
        parentTaskId: parentTaskId,
      );

  Future<void> detachFromParent(Id childTaskId) =>
      _deps.taskEventLinks.detachTaskFromParent(childTaskId);

  Future<void> deleteAttachment(Id attachmentId) =>
      _deps.attachmentRepository.delete(attachmentId);

  Future<void> restoreAttachment(TaskAttachment attachment) =>
      _deps.attachmentRepository.save(attachment);

  Future<void> updateAttachment(TaskAttachment attachment) =>
      _deps.attachmentRepository.update(attachment);

  Future<bool> toggleAttachmentChecklistItem({
    required Id attachmentId,
    required int itemLocalId,
  }) async {
    final TaskAttachment? attachment =
        await _deps.attachmentRepository.getById(attachmentId);
    if (attachment == null) {
      return false;
    }
    if (!TaskAttachmentChecklist.toggleItem(attachment, itemLocalId)) {
      return false;
    }
    await _deps.attachmentRepository.update(attachment);
    return true;
  }

  Future<void> linkToCalendarEvent({
    required Id taskId,
    required Id eventId,
  }) =>
      _deps.taskEventLinks.linkTaskToEvent(
        taskId: taskId,
        eventId: eventId,
      );

  Future<void> unlinkFromCalendarEvent(Id taskId) =>
      _deps.taskEventLinks.unlinkTaskFromEvent(taskId);

  Future<bool> updateTaskFields(Task updated) async {
    final Task? existing = await _deps.todoRepository.getTaskById(updated.id);
    if (existing == null) {
      return false;
    }
    existing
      ..title = updated.title
      ..description = updated.description
      ..dueDate = updated.dueDate
      ..priority = updated.priority
      ..calendarId = updated.calendarId
      ..reminderAt = updated.reminderAt
      ..updatedAt = updated.updatedAt;
    await _deps.todoRepository.updateTask(existing);
    await _deps.reminderSync.syncTask(existing);
    return true;
  }

  Future<DeletedTaskSnapshot?> captureTaskForDelete(Id taskId) async {
    final Task? task = await _deps.todoRepository.getTaskById(taskId);
    if (task == null) {
      return null;
    }
    final List<TaskAttachment> attachments =
        await _deps.attachmentRepository.getAttachmentsForTask(taskId);
    final List<Task> children =
        await _deps.todoRepository.getAllChildTasks(taskId);
    return DeletedTaskSnapshot(
      task: taskSnapshot(task),
      attachments: attachments.map(taskAttachmentSnapshot).toList(),
      children: children
          .map(
            (Task child) => DeletedChildParentState(
              childId: child.id,
              parentTaskId: taskId,
              sortOrder: child.sortOrder,
            ),
          )
          .toList(),
      linkedEventId: task.linkedEventId,
    );
  }

  Future<void> deleteTask(Id taskId) async {
    await _deps.taskEventLinks.unlinkTaskFromEvent(taskId);
    await _deps.attachmentRepository.deleteAllForTask(taskId);

    final List<Task> children =
        await _deps.todoRepository.getAllChildTasks(taskId);
    for (final Task child in children) {
      TaskHierarchy.detach(child);
      await _deps.todoRepository.updateTask(child);
    }

    await _deps.reminderSync.cancelTask(taskId);
    await _deps.todoRepository.deleteTask(taskId);
  }

  Future<void> restoreDeletedTask(DeletedTaskSnapshot snapshot) async {
    await _deps.todoRepository.saveTask(snapshot.task);
    for (final TaskAttachment attachment in snapshot.attachments) {
      await _deps.attachmentRepository.save(attachment);
    }
    for (final DeletedChildParentState child in snapshot.children) {
      final Task? task = await _deps.todoRepository.getTaskById(child.childId);
      if (task == null) {
        continue;
      }
      task.parentTaskId = child.parentTaskId;
      task.sortOrder = child.sortOrder;
      await _deps.todoRepository.updateTask(task);
    }
    final Id? eventId = snapshot.linkedEventId;
    if (eventId != null) {
      await _deps.taskEventLinks.linkTaskToEvent(
        taskId: snapshot.task.id,
        eventId: eventId,
      );
    }
    await _deps.reminderSync.syncTask(snapshot.task);
  }
}
