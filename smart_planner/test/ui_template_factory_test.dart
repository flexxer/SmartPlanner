import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/templates/domain/ui_template_embedded_attachment_codec.dart';
import 'package:smart_planner/features/templates/domain/ui_template_factory.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

void main() {
  group('UiTemplateFactory', () {
    test('fromTask copies checklist lines and location attachment', () {
      final Task task = Task.create(title: 'Сборы', description: 'Не опаздывать');
      final TaskAttachment checklist = TaskAttachment.create(
        taskId: 1,
        type: TaskAttachmentType.checklist,
        payloadJson: TaskAttachmentCodec.encodeMap(
          ChecklistAttachmentPayload(
            title: 'Список',
            items: <ChecklistItemPayload>[
              const ChecklistItemPayload(localId: 1, text: 'Скрипка'),
              const ChecklistItemPayload(localId: 2, text: 'Ноты'),
            ],
          ).toJson(),
        ),
      );
      final TaskAttachment location = TaskAttachment.create(
        taskId: 1,
        type: TaskAttachmentType.location,
        payloadJson: TaskAttachmentCodec.encodeMap(
          const LocationAttachmentPayload(
            latitude: 55.75,
            longitude: 37.62,
            placeName: 'Зал',
          ).toJson(),
        ),
        label: 'Репетиция',
      );

      final UiTemplate template = UiTemplateFactory.fromTask(
        task: task,
        attachments: <TaskAttachment>[checklist, location],
      );

      expect(template.title, 'Сборы');
      expect(template.templateDescription, 'Не опаздывать');
      expect(template.checklistItems, <String>['Скрипка', 'Ноты']);
      final UiTemplateEmbeddedAttachment? embedded =
          UiTemplateEmbeddedAttachmentCodec.decode(
        template.embeddedAttachmentJson,
      );
      expect(embedded?.type, TaskAttachmentType.location);
      expect(embedded?.label, 'Репетиция');
    });
  });
}
