import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';

part 'ui_template_model.g.dart';

/// Isar persistence model for [UiTemplate]. Keeps all Isar metadata out of the
/// domain layer.
@collection
@Name('UiTemplate')
class UiTemplateModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  String? templateDescription;

  List<String> checklistItems = <String>[];

  String? embeddedAttachmentJson;

  /// Maps this persistence row to the pure domain entity.
  UiTemplate toDomain() => UiTemplate(id: id)
    ..title = title
    ..templateDescription = templateDescription
    ..checklistItems = List<String>.from(checklistItems)
    ..embeddedAttachmentJson = embeddedAttachmentJson;

  /// Maps a pure domain entity to a persistence row.
  static UiTemplateModel fromDomain(UiTemplate template) {
    final UiTemplateModel model = UiTemplateModel()
      ..title = template.title
      ..templateDescription = template.templateDescription
      ..checklistItems = List<String>.from(template.checklistItems)
      ..embeddedAttachmentJson = template.embeddedAttachmentJson;
    if (template.id > 0) {
      model.id = template.id;
    }
    return model;
  }
}
