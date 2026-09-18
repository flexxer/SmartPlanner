import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/data/models/task_attachment_model.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// CRUD for [TaskAttachment] and attachment files. Maps between the pure domain
/// entity and the [TaskAttachmentModel] persistence row, and reports failures
/// as [Result].
class TaskAttachmentRepository {
  TaskAttachmentRepository({
    this.isar,
    AttachmentFileStore? fileStore,
  }) : _fileStore = fileStore ?? AttachmentFileStore();

  final Isar? isar;
  final AttachmentFileStore _fileStore;

  Isar get _db => isar ?? IsarDatabase.instance;

  AttachmentFileStore get fileStore => _fileStore;

  Future<Result<TaskAttachment?>> getById(int id) async {
    try {
      final TaskAttachmentModel? model = await _db.taskAttachmentModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load task attachment $id: $error', stackTrace),
      );
    }
  }

  Future<Result<List<TaskAttachment>>> getAttachmentsForTask(int taskId) async {
    try {
      final List<TaskAttachmentModel> list = await _db.taskAttachmentModels
          .filter()
          .taskIdEqualTo(taskId)
          .findAll();
      list.sort(
        (TaskAttachmentModel a, TaskAttachmentModel b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );
      return Success(
        list.map((TaskAttachmentModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load task attachments: $error', stackTrace),
      );
    }
  }

  Future<Result<Map<int, List<TaskAttachment>>>> getAttachmentsForTasks(
    List<int> taskIds,
  ) async {
    try {
      final Map<int, List<TaskAttachment>> result = <int, List<TaskAttachment>>{};
      for (final int taskId in taskIds) {
        result[taskId] =
            (await getAttachmentsForTask(taskId)).getOrElse((_) => <TaskAttachment>[]);
      }
      return Success(result);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load task attachments: $error', stackTrace),
      );
    }
  }

  Future<Result<int>> nextSortOrder(int taskId) async {
    final Result<List<TaskAttachment>> result = await getAttachmentsForTask(taskId);
    return result.map(
      (List<TaskAttachment> list) => list.isEmpty ? 0 : list.last.sortOrder + 1,
    );
  }

  Future<Result<TaskAttachment>> save(TaskAttachment attachment) async {
    try {
      final TaskAttachmentModel model = TaskAttachmentModel.fromDomain(attachment);
      await _db.writeTxn(() => _db.taskAttachmentModels.put(model));
      return Success(model.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to save task attachment: $error', stackTrace),
      );
    }
  }

  Future<Result<TaskAttachment>> update(TaskAttachment attachment) =>
      save(attachment);

  /// Persists [sortOrder] for each attachment id in [orderedIds].
  Future<Result<bool>> reorder(List<int> orderedIds) async {
    try {
      await _db.writeTxn(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          final TaskAttachmentModel? model =
              await _db.taskAttachmentModels.get(orderedIds[i]);
          if (model == null) {
            continue;
          }
          model.sortOrder = i;
          await _db.taskAttachmentModels.put(model);
        }
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to reorder task attachments: $error', stackTrace),
      );
    }
  }

  /// Removes all attachments (and image files) for [taskId].
  Future<Result<bool>> deleteAllForTask(int taskId) async {
    final List<TaskAttachment> attachments =
        (await getAttachmentsForTask(taskId)).getOrElse((_) => <TaskAttachment>[]);
    for (final TaskAttachment attachment in attachments) {
      await delete(attachment.id);
    }
    return const Success(true);
  }

  Future<Result<bool>> delete(int attachmentId) async {
    try {
      final TaskAttachmentModel? model =
          await _db.taskAttachmentModels.get(attachmentId);
      if (model != null) {
        await _deleteStoredFileIfNeeded(model.toDomain());
      }
      final bool deleted = await _db.writeTxn(
        () => _db.taskAttachmentModels.delete(attachmentId),
      );
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to delete task attachment: $error', stackTrace),
      );
    }
  }

  Future<Result<bool>> copyAttachmentsToTask({
    required int fromTaskId,
    required int toTaskId,
  }) async {
    try {
      final List<TaskAttachment> source =
          (await getAttachmentsForTask(fromTaskId))
              .getOrElse((_) => <TaskAttachment>[]);
      for (final TaskAttachment item in source) {
        String payloadJson = item.payloadJson;
        if (item.type == TaskAttachmentType.image) {
          final ImageAttachmentPayload image = TaskAttachmentCodec.image(item);
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
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to copy task attachments: $error', stackTrace),
      );
    }
  }

  Future<void> _deleteStoredFileIfNeeded(TaskAttachment attachment) async {
    if (attachment.type == TaskAttachmentType.image) {
      final ImageAttachmentPayload payload = TaskAttachmentCodec.image(attachment);
      await _fileStore.deleteIfExists(payload.relativePath);
    } else if (attachment.type == TaskAttachmentType.file) {
      final FileAttachmentPayload payload =
          TaskAttachmentCodec.fileRef(AttachmentRef.fromTask(attachment));
      await _fileStore.deleteIfExists(payload.relativePath);
    }
  }
}
