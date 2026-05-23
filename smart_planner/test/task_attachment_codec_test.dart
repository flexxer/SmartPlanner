import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

void main() {
  test('contact payload roundtrip', () {
    final TaskAttachment attachment = TaskAttachment.create(
      taskId: 1,
      type: TaskAttachmentType.contact,
      payloadJson: TaskAttachmentCodec.encodeMap(
        const ContactAttachmentPayload(
          displayName: 'Мама',
          phones: <String>['+79990001122'],
        ).toJson(),
      ),
    );

    final ContactAttachmentPayload decoded =
        TaskAttachmentCodec.contact(attachment);
    expect(decoded.displayName, 'Мама');
    expect(decoded.primaryPhone, '+79990001122');
    expect(TaskAttachmentCodec.summaryLabel(attachment), 'Мама');
  });

  test('location payload uses placeName and user label override', () {
    const LocationAttachmentPayload payload = LocationAttachmentPayload(
      latitude: 55.75,
      longitude: 37.61,
      placeName: 'Красная площадь, Москва, Россия',
      label: 'Встреча у ГУМа',
    );

    final TaskAttachment attachment = TaskAttachment.create(
      taskId: 1,
      type: TaskAttachmentType.location,
      payloadJson: TaskAttachmentCodec.encodeMap(payload.toJson()),
    );

    final LocationAttachmentPayload decoded =
        TaskAttachmentCodec.location(attachment);
    expect(decoded.placeName, 'Красная площадь, Москва, Россия');
    expect(decoded.resolvedPlaceTitle, 'Встреча у ГУМа');
    expect(
      TaskAttachmentCodec.locationDisplayTitle(decoded),
      'Встреча у ГУМа',
    );
    expect(TaskAttachmentCodec.summaryLabel(attachment), 'Встреча у ГУМа');
  });

  test('legacy location payload with label only maps to placeName', () {
    final TaskAttachment attachment = TaskAttachment.create(
      taskId: 1,
      type: TaskAttachmentType.location,
      payloadJson: TaskAttachmentCodec.encodeMap(
        <String, dynamic>{
          'latitude': 55.75,
          'longitude': 37.61,
          'label': 'Старый адрес',
        },
      ),
    );

    final LocationAttachmentPayload decoded =
        TaskAttachmentCodec.location(attachment);
    expect(decoded.placeName, 'Старый адрес');
    expect(decoded.resolvedPlaceTitle, 'Старый адрес');
    expect(TaskAttachmentCodec.summaryLabel(attachment), 'Старый адрес');
  });
}
