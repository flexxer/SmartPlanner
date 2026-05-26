import 'package:isar/isar.dart';

part 'ui_template.g.dart';

/// Reusable task blueprint (title, checklist lines, optional embedded attachment).
@collection
class UiTemplate {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  String? templateDescription;

  /// Plain checklist line texts (applied as a new checklist attachment).
  List<String> checklistItems = <String>[];

  /// JSON snapshot of a location, URL, or note attachment (see [UiTemplateEmbeddedAttachmentCodec]).
  String? embeddedAttachmentJson;

  UiTemplate();

  factory UiTemplate.create({
    required String title,
    String? templateDescription,
    List<String> checklistItems = const <String>[],
    String? embeddedAttachmentJson,
  }) {
    return UiTemplate()
      ..title = title
      ..templateDescription = templateDescription
      ..checklistItems = List<String>.from(checklistItems)
      ..embeddedAttachmentJson = embeddedAttachmentJson;
  }
}
