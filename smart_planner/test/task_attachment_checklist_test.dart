import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

void main() {
  test('toggle checklist item updates payload', () {
    final TaskAttachment attachment = TaskAttachment.create(
      taskId: 1,
      type: TaskAttachmentType.checklist,
      payloadJson: TaskAttachmentCodec.encodeMap(
        ChecklistAttachmentPayload(
          items: <ChecklistItemPayload>[
            ChecklistItemPayload(localId: 1, text: 'A'),
            ChecklistItemPayload(localId: 2, text: 'B', isCompleted: true),
          ],
        ).toJson(),
      ),
    );

    expect(TaskAttachmentChecklist.toggleItem(attachment, 1), isTrue);

    final ChecklistAttachmentPayload updated =
        TaskAttachmentCodec.checklist(attachment);
    expect(updated.items.first.isCompleted, isTrue);
    expect(updated.items[1].isCompleted, isTrue);
  });
}
