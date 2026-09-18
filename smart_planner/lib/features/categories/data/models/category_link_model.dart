import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/categories/domain/entities/category_link.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';

part 'category_link_model.g.dart';

/// Isar persistence model for [CategoryLink].
@collection
@Name('CategoryLink')
class CategoryLinkModel {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  late TaggedEntityType entityType;

  @Index()
  late int entityId;

  @Index()
  late int categoryId;

  CategoryLink toDomain() => CategoryLink(id: id)
    ..entityType = entityType
    ..entityId = entityId
    ..categoryId = categoryId;

  static CategoryLinkModel fromDomain(CategoryLink link) {
    final CategoryLinkModel model = CategoryLinkModel()
      ..entityType = link.entityType
      ..entityId = link.entityId
      ..categoryId = link.categoryId;
    if (link.id > 0) {
      model.id = link.id;
    }
    return model;
  }
}
