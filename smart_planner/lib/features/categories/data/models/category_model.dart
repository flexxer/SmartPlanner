import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/categories/domain/entities/category.dart';

part 'category_model.g.dart';

/// Isar persistence model for [Category].
@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  int colorValue = 0xFF5C6BC0;

  int sortOrder = 0;

  bool isArchived = false;

  DateTime updatedAt = DateTime.now();

  Category toDomain() => Category(id: id)
    ..name = name
    ..colorValue = colorValue
    ..sortOrder = sortOrder
    ..isArchived = isArchived
    ..updatedAt = updatedAt;

  static CategoryModel fromDomain(Category category) {
    final CategoryModel model = CategoryModel()
      ..name = category.name
      ..colorValue = category.colorValue
      ..sortOrder = category.sortOrder
      ..isArchived = category.isArchived
      ..updatedAt = category.updatedAt;
    if (category.id > 0) {
      model.id = category.id;
    }
    return model;
  }
}
