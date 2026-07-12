import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';

part 'category_link.g.dart';

/// Many-to-many junction between a tagged entity and a [Category].
@collection
class CategoryLink {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  late TaggedEntityType entityType;

  @Index()
  late int entityId;

  @Index()
  late int categoryId;

  CategoryLink();

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
}
