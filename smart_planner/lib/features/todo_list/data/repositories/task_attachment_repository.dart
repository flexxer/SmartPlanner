import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// CRUD for [TaskAttachment] and attachment files.
class TaskAttachmentRepository {
  TaskAttachmentRepository({
    Isar? isar,
    AttachmentFileStore? fileStore,
  })  : _isar = isar,
        _fileStore = fileStore ?? AttachmentFileStore();

  final Isar? _isar;
  final AttachmentFileStore _fileStore;

  Isar get _db => _isar ?? IsarDatabase.instance;

  AttachmentFileStore get fileStore => _fileStore;

  Future<TaskAttachment?> getById(Id id) => _db.taskAttachments.get(id);

  Future<List<TaskAttachment>> getAttachmentsForTask(Id taskId) async {
    final List<TaskAttachment> list = await _db.taskAttachments
        .filter()
        .taskIdEqualTo(taskId)
        .findAll();
    list.sort(
      (TaskAttachment a, TaskAttachment b) =>
          a.sortOrder.compareTo(b.sortOrder),
    );
    return list;
  }

  Future<Map<Id, List<TaskAttachment>>> getAttachmentsForTasks(
    List<Id> taskIds,
  ) async {
    final Map<Id, List<TaskAttachment>> result = <Id, List<TaskAttachment>>{};
    for (final Id taskId in taskIds) {
      result[taskId] = await getAttachmentsForTask(taskId);
    }
    return result;
  }

  Future<int> nextSortOrder(Id taskId) async {
    final List<TaskAttachment> existing = await getAttachmentsForTask(taskId);
    if (existing.isEmpty) {
      return 0;
    }
    return existing.last.sortOrder + 1;
  }

  Future<Id> save(TaskAttachment attachment) =>
      _db.writeTxn(() => _db.taskAttachments.put(attachment));

  Future<void> update(TaskAttachment attachment) async {
    await _db.writeTxn(() => _db.taskAttachments.put(attachment));
  }

  /// Persists [sortOrder] for each attachment id in [orderedIds].
  Future<void> reorder(List<Id> orderedIds) async {
    await _db.writeTxn(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        final TaskAttachment? attachment =
            await _db.taskAttachments.get(orderedIds[i]);
        if (attachment == null) {
          continue;
        }
        attachment.sortOrder = i;
        await _db.taskAttachments.put(attachment);
      }
    });
  }

  /// Removes all attachments (and image files) for [taskId].
  Future<void> deleteAllForTask(Id taskId) async {
    final List<TaskAttachment> attachments = await getAttachmentsForTask(taskId);
    for (final TaskAttachment attachment in attachments) {
      await delete(attachment.id);
    }
  }

  Future<void> delete(Id attachmentId) async {
    final TaskAttachment? attachment = await _db.taskAttachments.get(attachmentId);
    if (attachment == null) {
      return;
    }
    await _deleteStoredFileIfNeeded(attachment);
    await _db.writeTxn(() => _db.taskAttachments.delete(attachmentId));
  }

  Future<void> copyAttachmentsToTask({
    required Id fromTaskId,
    required Id toTaskId,
  }) async {
    final List<TaskAttachment> source = await getAttachmentsForTask(fromTaskId);
    for (final TaskAttachment item in source) {
      String payloadJson = item.payloadJson;
      if (item.type == TaskAttachmentType.image) {
        final ImageAttachmentPayload image =
            TaskAttachmentCodec.image(item);
        final String newPath =
            await _fileStore.copyImageForReopen(image.relativePath);
        payloadJson = TaskAttachmentCodec.encodeMap(
          ImageAttachmentPayload(
            relativePath: newPath,
            mimeType: image.mimeType,
          ).toJson(),
        );
      } else if (item.type == TaskAttachmentType.file) {
        final FileAttachmentPayload file =
            TaskAttachmentCodec.fileRef(AttachmentRef.fromTask(item));
        final String newPath =
            await _fileStore.copyStoredFileForReopen(file.relativePath);
        payloadJson = TaskAttachmentCodec.encodeMap(
          FileAttachmentPayload(
            relativePath: newPath,
            fileName: file.fileName,
            mimeType: file.mimeType,
          ).toJson(),
        );
      }
      await save(
        TaskAttachment.create(
          taskId: toTaskId,
          type: item.type,
          payloadJson: payloadJson,
          label: item.label,
          sortOrder: item.sortOrder,
        ),
      );
    }
  }

  Future<void> _deleteStoredFileIfNeeded(TaskAttachment attachment) async {
    if (attachment.type == TaskAttachmentType.image) {
      final ImageAttachmentPayload payload =
          TaskAttachmentCodec.image(attachment);
      await _fileStore.deleteIfExists(payload.relativePath);
    } else if (attachment.type == TaskAttachmentType.file) {
      final FileAttachmentPayload payload =
          TaskAttachmentCodec.fileRef(AttachmentRef.fromTask(attachment));
      await _fileStore.deleteIfExists(payload.relativePath);
    }
  }
}
