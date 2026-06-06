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

  test('toggle moves completed item to end when enabled', () {
    final TaskAttachment attachment = TaskAttachment.create(
      taskId: 1,
      type: TaskAttachmentType.checklist,
      payloadJson: TaskAttachmentCodec.encodeMap(
        ChecklistAttachmentPayload(
          items: <ChecklistItemPayload>[
            ChecklistItemPayload(localId: 1, text: 'A'),
            ChecklistItemPayload(localId: 2, text: 'B'),
            ChecklistItemPayload(localId: 3, text: 'C', isCompleted: true),
          ],
        ).toJson(),
      ),
    );

    expect(TaskAttachmentChecklist.toggleItem(attachment, 1), isTrue);

    final ChecklistAttachmentPayload updated =
        TaskAttachmentCodec.checklist(attachment);
    expect(updated.items.map((ChecklistItemPayload i) => i.localId).toList(),
        <int>[2, 1, 3]);
    expect(updated.items.last.isCompleted, isTrue);
  });

  test('toggle keeps order when moveCompletedToEnd is disabled', () {
    final TaskAttachment attachment = TaskAttachment.create(
      taskId: 1,
      type: TaskAttachmentType.checklist,
      payloadJson: TaskAttachmentCodec.encodeMap(
        ChecklistAttachmentPayload(
          moveCompletedToEnd: false,
          items: <ChecklistItemPayload>[
            ChecklistItemPayload(localId: 1, text: 'A'),
            ChecklistItemPayload(localId: 2, text: 'B'),
          ],
        ).toJson(),
      ),
    );

    expect(TaskAttachmentChecklist.toggleItem(attachment, 1), isTrue);

    final ChecklistAttachmentPayload updated =
        TaskAttachmentCodec.checklist(attachment);
    expect(updated.items.map((ChecklistItemPayload i) => i.localId).toList(),
        <int>[1, 2]);
    expect(updated.items.first.isCompleted, isTrue);
  });

  test('displayItems puts uncompleted first by default', () {
    const ChecklistAttachmentPayload checklist = ChecklistAttachmentPayload(
      items: <ChecklistItemPayload>[
        ChecklistItemPayload(localId: 1, text: 'Done', isCompleted: true),
        ChecklistItemPayload(localId: 2, text: 'Todo'),
      ],
    );

    final List<ChecklistItemPayload> displayed =
        TaskAttachmentChecklist.displayItems(checklist);
    expect(displayed.first.localId, 2);
    expect(displayed.last.localId, 1);
  });

  test('legacy checklist payload defaults moveCompletedToEnd to true', () {
    final ChecklistAttachmentPayload checklist =
        ChecklistAttachmentPayload.fromJson(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'localId': 1, 'text': 'A'},
      ],
    });

    expect(checklist.moveCompletedToEnd, isTrue);
  });
}
