import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// Checklist operations on a checklist [TaskAttachment].
class TaskAttachmentChecklist {
  TaskAttachmentChecklist._();

  static int nextItemLocalId(List<ChecklistItemPayload> items) {
    if (items.isEmpty) {
      return 1;
    }
    int maxId = 0;
    for (final ChecklistItemPayload item in items) {
      if (item.localId > maxId) {
        maxId = item.localId;
      }
    }
    return maxId + 1;
  }

  static bool toggleItem(TaskAttachment attachment, int itemLocalId) {
    final ChecklistAttachmentPayload checklist =
        TaskAttachmentCodec.checklist(attachment);
    final int index = checklist.items.indexWhere(
      (ChecklistItemPayload i) => i.localId == itemLocalId,
    );
    if (index < 0) {
      return false;
    }
    final List<ChecklistItemPayload> updated =
        List<ChecklistItemPayload>.from(checklist.items);
    final ChecklistItemPayload current = updated[index];
    updated[index] = ChecklistItemPayload(
      localId: current.localId,
      text: current.text,
      isCompleted: !current.isCompleted,
    );
    attachment.payloadJson = TaskAttachmentCodec.encodeMap(
      ChecklistAttachmentPayload(
        title: checklist.title,
        items: updated,
      ).toJson(),
    );
    return true;
  }

  static ChecklistProgress progress(ChecklistAttachmentPayload checklist) {
    if (checklist.items.isEmpty) {
      return const ChecklistProgress(completed: 0, total: 0);
    }
    final int completed =
        checklist.items.where((ChecklistItemPayload i) => i.isCompleted).length;
    return ChecklistProgress(
      completed: completed,
      total: checklist.items.length,
    );
  }
}

class ChecklistProgress {
  const ChecklistProgress({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  bool get hasItems => total > 0;
}
