import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/attachment_templates/data/models/attachment_template_model.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// CRUD for [AttachmentTemplate] presets. Maps between the pure domain entity
/// and the [AttachmentTemplateModel] persistence row, and reports failures as
/// [Result].
class AttachmentTemplateRepository {
  AttachmentTemplateRepository({this.isar});

  final Isar? isar;

  Isar get _db => isar ?? IsarDatabase.instance;

  Future<Result<List<AttachmentTemplate>>> getAll() async {
    try {
      final List<AttachmentTemplateModel> models =
          await _db.attachmentTemplateModels.where().findAll();
      models.sort(
        (AttachmentTemplateModel a, AttachmentTemplateModel b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );
      return Success(
        models
            .map((AttachmentTemplateModel m) => m.toDomain())
            .toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load attachment templates: $error', stackTrace),
      );
    }
  }

  Future<Result<List<AttachmentTemplate>>> getByType(
    TaskAttachmentType type,
  ) async {
    final Result<List<AttachmentTemplate>> result = await getAll();
    return result.map(
      (List<AttachmentTemplate> list) =>
          list.where((AttachmentTemplate t) => t.type == type).toList(
                growable: false,
              ),
    );
  }

  Future<Result<AttachmentTemplate?>> getById(int id) async {
    try {
      final AttachmentTemplateModel? model =
          await _db.attachmentTemplateModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load attachment template $id: $error', stackTrace),
      );
    }
  }

  Future<Result<int>> nextSortOrder() async {
    final Result<List<AttachmentTemplate>> result = await getAll();
    return result.map(
      (List<AttachmentTemplate> list) =>
          list.isEmpty ? 0 : list.last.sortOrder + 1,
    );
  }

  Future<Result<AttachmentTemplate>> save(AttachmentTemplate template) async {
    try {
      final AttachmentTemplateModel model =
          AttachmentTemplateModel.fromDomain(template);
      await _db.writeTxn(() => _db.attachmentTemplateModels.put(model));
      return Success(model.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to save attachment template: $error', stackTrace),
      );
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final bool deleted =
          await _db.writeTxn(() => _db.attachmentTemplateModels.delete(id));
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to delete attachment template $id: $error', stackTrace),
      );
    }
  }

  /// Persists [sortOrder] for each template id in [orderedIds].
  Future<Result<bool>> reorder(List<int> orderedIds) async {
    try {
      await _db.writeTxn(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          final AttachmentTemplateModel? model =
              await _db.attachmentTemplateModels.get(orderedIds[i]);
          if (model == null) {
            continue;
          }
          model.sortOrder = i;
          await _db.attachmentTemplateModels.put(model);
        }
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to reorder attachment templates: $error', stackTrace),
      );
    }
  }
}
