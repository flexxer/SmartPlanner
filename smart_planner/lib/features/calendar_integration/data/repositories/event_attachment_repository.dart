import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/calendar_integration/data/models/event_attachment_model.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// CRUD for [EventAttachment] and stored files. Maps between the pure domain
/// entity and the [EventAttachmentModel] persistence row, and reports failures
/// as [Result].
class EventAttachmentRepository {
  EventAttachmentRepository({
    this.isar,
    AttachmentFileStore? fileStore,
  }) : _fileStore = fileStore ?? AttachmentFileStore();

  final Isar? isar;
  final AttachmentFileStore _fileStore;

  Isar get _db => isar ?? IsarDatabase.instance;

  AttachmentFileStore get fileStore => _fileStore;

  Future<Result<EventAttachment?>> getById(int id) async {
    try {
      final EventAttachmentModel? model =
          await _db.eventAttachmentModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load event attachment $id: $error', stackTrace),
      );
    }
  }

  Future<Result<List<EventAttachment>>> getAttachmentsForEvent(
    int eventId,
  ) async {
    try {
      final List<EventAttachmentModel> list = await _db.eventAttachmentModels
          .filter()
          .eventIdEqualTo(eventId)
          .findAll();
      list.sort(
        (EventAttachmentModel a, EventAttachmentModel b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );
      return Success(
        list
            .map((EventAttachmentModel m) => m.toDomain())
            .toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load event attachments: $error', stackTrace),
      );
    }
  }

  Future<Result<int>> nextSortOrder(int eventId) async {
    final Result<List<EventAttachment>> result =
        await getAttachmentsForEvent(eventId);
    return result.map(
      (List<EventAttachment> list) => list.isEmpty ? 0 : list.last.sortOrder + 1,
    );
  }

  Future<Result<EventAttachment>> save(EventAttachment attachment) async {
    try {
      final EventAttachmentModel model =
          EventAttachmentModel.fromDomain(attachment);
      await _db.writeTxn(() => _db.eventAttachmentModels.put(model));
      return Success(model.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to save event attachment: $error', stackTrace),
      );
    }
  }

  Future<Result<EventAttachment>> update(EventAttachment attachment) =>
      save(attachment);

  Future<Result<bool>> deleteAllForEvent(int eventId) async {
    final List<EventAttachment> attachments =
        (await getAttachmentsForEvent(eventId))
            .getOrElse((_) => <EventAttachment>[]);
    for (final EventAttachment attachment in attachments) {
      await delete(attachment.id);
    }
    return const Success(true);
  }

  Future<Result<bool>> delete(int attachmentId) async {
    try {
      final EventAttachmentModel? model =
          await _db.eventAttachmentModels.get(attachmentId);
      if (model != null) {
        await _deleteStoredFileIfNeeded(model.toDomain());
      }
      final bool deleted = await _db.writeTxn(
        () => _db.eventAttachmentModels.delete(attachmentId),
      );
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to delete event attachment: $error', stackTrace),
      );
    }
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
