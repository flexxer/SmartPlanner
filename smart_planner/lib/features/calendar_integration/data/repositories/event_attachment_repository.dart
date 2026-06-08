import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// CRUD for [EventAttachment] and stored files.
class EventAttachmentRepository {
  EventAttachmentRepository({
    Isar? isar,
    AttachmentFileStore? fileStore,
  })  : _isar = isar,
        _fileStore = fileStore ?? AttachmentFileStore();

  final Isar? _isar;
  final AttachmentFileStore _fileStore;

  Isar get _db => _isar ?? IsarDatabase.instance;

  AttachmentFileStore get fileStore => _fileStore;

  Future<EventAttachment?> getById(Id id) => _db.eventAttachments.get(id);

  Future<List<EventAttachment>> getAttachmentsForEvent(Id eventId) async {
    final List<EventAttachment> list = await _db.eventAttachments
        .filter()
        .eventIdEqualTo(eventId)
        .findAll();
    list.sort(
      (EventAttachment a, EventAttachment b) =>
          a.sortOrder.compareTo(b.sortOrder),
    );
    return list;
  }

  Future<int> nextSortOrder(Id eventId) async {
    final List<EventAttachment> existing =
        await getAttachmentsForEvent(eventId);
    if (existing.isEmpty) {
      return 0;
    }
    return existing.last.sortOrder + 1;
  }

  Future<Id> save(EventAttachment attachment) =>
      _db.writeTxn(() => _db.eventAttachments.put(attachment));

  Future<void> update(EventAttachment attachment) async {
    await _db.writeTxn(() => _db.eventAttachments.put(attachment));
  }

  Future<void> deleteAllForEvent(Id eventId) async {
    final List<EventAttachment> attachments =
        await getAttachmentsForEvent(eventId);
    for (final EventAttachment attachment in attachments) {
      await delete(attachment.id);
    }
  }

  Future<void> delete(Id attachmentId) async {
    final EventAttachment? attachment =
        await _db.eventAttachments.get(attachmentId);
    if (attachment == null) {
      return;
    }
    await _deleteStoredFileIfNeeded(attachment);
    await _db.writeTxn(() => _db.eventAttachments.delete(attachmentId));
  }

  Future<void> _deleteStoredFileIfNeeded(EventAttachment attachment) async {
    if (attachment.type == TaskAttachmentType.image) {
      final ImageAttachmentPayload payload =
          TaskAttachmentCodec.imageRef(AttachmentRef.fromEvent(attachment));
      await _fileStore.deleteIfExists(payload.relativePath);
    } else if (attachment.type == TaskAttachmentType.file) {
      final FileAttachmentPayload payload =
          TaskAttachmentCodec.fileRef(AttachmentRef.fromEvent(attachment));
      await _fileStore.deleteIfExists(payload.relativePath);
    }
  }
}
