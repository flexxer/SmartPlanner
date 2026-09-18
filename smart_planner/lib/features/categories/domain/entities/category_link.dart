import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';

/// Many-to-many junction between a tagged entity and a [Category].
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `CategoryLinkModel` in the data layer.
class CategoryLink {
  CategoryLink({this.id = 0});

  factory CategoryLink.create({
    required TaggedEntityType entityType,
    required int entityId,
    required int categoryId,
  }) {
    return CategoryLink()
      ..entityType = entityType
      ..entityId = entityId
      ..categoryId = categoryId;
  }

  /// Database id; `0` until persisted.
  int id;

  TaggedEntityType entityType = TaggedEntityType.task;

  int entityId = 0;

  int categoryId = 0;
}
