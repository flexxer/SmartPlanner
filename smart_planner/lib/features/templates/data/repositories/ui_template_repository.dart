import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';

/// Isar CRUD for [UiTemplate] blueprints.
class UiTemplateRepository {
  UiTemplateRepository({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<UiTemplate>> getAll() =>
      _db.uiTemplates.where().sortByTitle().findAll();

  Future<UiTemplate?> getById(Id id) => _db.uiTemplates.get(id);

  Future<Id> save(UiTemplate template) =>
      _db.writeTxn(() => _db.uiTemplates.put(template));

  Future<bool> delete(Id id) =>
      _db.writeTxn(() => _db.uiTemplates.delete(id));
}
