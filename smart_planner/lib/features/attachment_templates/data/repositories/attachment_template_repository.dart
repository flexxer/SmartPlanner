import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// CRUD for [AttachmentTemplate] presets.
class AttachmentTemplateRepository {
  AttachmentTemplateRepository({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<AttachmentTemplate>> getAll() async {
    final List<AttachmentTemplate> list =
        await _db.attachmentTemplates.where().findAll();
    list.sort(
      (AttachmentTemplate a, AttachmentTemplate b) =>
          a.sortOrder.compareTo(b.sortOrder),
    );
    return list;
  }

  Future<List<AttachmentTemplate>> getByType(TaskAttachmentType type) async {
    final List<AttachmentTemplate> all = await getAll();
    return all.where((AttachmentTemplate t) => t.type == type).toList();
  }

  Future<AttachmentTemplate?> getById(Id id) => _db.attachmentTemplates.get(id);

  Future<int> nextSortOrder() async {
    final List<AttachmentTemplate> existing = await getAll();
    if (existing.isEmpty) {
      return 0;
    }
    return existing.last.sortOrder + 1;
  }

  Future<Id> save(AttachmentTemplate template) =>
      _db.writeTxn(() => _db.attachmentTemplates.put(template));

  Future<void> delete(Id id) =>
      _db.writeTxn(() => _db.attachmentTemplates.delete(id));

  /// Persists [sortOrder] for each template id in [orderedIds].
  Future<void> reorder(List<Id> orderedIds) async {
    await _db.writeTxn(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        final AttachmentTemplate? template =
            await _db.attachmentTemplates.get(orderedIds[i]);
        if (template == null) {
          continue;
        }
        template.sortOrder = i;
        await _db.attachmentTemplates.put(template);
      }
    });
  }
}
