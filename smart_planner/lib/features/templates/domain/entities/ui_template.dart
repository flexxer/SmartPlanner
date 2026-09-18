/// Reusable task blueprint (title, checklist lines, optional embedded attachment).
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `UiTemplateModel` in the data layer.
class UiTemplate {
  UiTemplate({this.id = 0});

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

  /// Database id; `0` until persisted.
  int id;

  String title = '';

  String? templateDescription;

  /// Plain checklist line texts (applied as a new checklist attachment).
  List<String> checklistItems = <String>[];

  /// JSON snapshot of a location, URL, or note attachment (see
  /// `UiTemplateEmbeddedAttachmentCodec`).
  String? embeddedAttachmentJson;
}
