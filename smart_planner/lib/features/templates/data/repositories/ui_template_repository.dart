import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/templates/data/models/ui_template_model.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';

/// Isar CRUD for [UiTemplate] blueprints. Maps between the pure domain entity
/// and the [UiTemplateModel] persistence row, and reports failures as [Result].
class UiTemplateRepository {
  UiTemplateRepository({this.isar});

  final Isar? isar;

  Isar get _db => isar ?? IsarDatabase.instance;

  Future<Result<List<UiTemplate>>> getAll() async {
    try {
      final List<UiTemplateModel> models =
          await _db.uiTemplateModels.where().sortByTitle().findAll();
      return Success(
        models.map((UiTemplateModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load templates: $error', stackTrace),
      );
    }
  }

  Future<Result<UiTemplate?>> getById(int id) async {
    try {
      final UiTemplateModel? model = await _db.uiTemplateModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load template $id: $error', stackTrace),
      );
    }
  }

  Future<Result<UiTemplate>> save(UiTemplate template) async {
    try {
      final UiTemplateModel model = UiTemplateModel.fromDomain(template);
      await _db.writeTxn(() => _db.uiTemplateModels.put(model));
      return Success(model.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to save template: $error', stackTrace),
      );
    }
  }

  Future<Result<bool>> delete(int id) async {
    try {
      final bool deleted =
          await _db.writeTxn(() => _db.uiTemplateModels.delete(id));
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to delete template $id: $error', stackTrace),
      );
    }
  }
}
