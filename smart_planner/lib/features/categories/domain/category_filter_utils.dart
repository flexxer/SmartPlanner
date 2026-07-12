import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';

/// Client-side category filter helpers (OR across selected tags).
class CategoryFilterUtils {
  const CategoryFilterUtils._();

  static bool matchesAnySelectedCategory({
    required int entityId,
    required List<Id> selectedCategoryIds,
    required Map<int, List<Id>> tagIdsByEntityId,
  }) {
    if (selectedCategoryIds.isEmpty) {
      return true;
    }
    final List<Id> entityTags = tagIdsByEntityId[entityId] ?? const <Id>[];
    final Set<Id> selected = selectedCategoryIds.toSet();
    for (final Id tagId in entityTags) {
      if (selected.contains(tagId)) {
        return true;
      }
    }
    return false;
  }

  static List<T> filterEntities<T>({
    required List<T> items,
    required Id Function(T item) idFor,
    required List<Id> selectedCategoryIds,
    required Map<int, List<Id>> tagIdsByEntityId,
  }) {
    if (selectedCategoryIds.isEmpty) {
      return items;
    }
    return items
        .where(
          (T item) => matchesAnySelectedCategory(
            entityId: idFor(item),
            selectedCategoryIds: selectedCategoryIds,
            tagIdsByEntityId: tagIdsByEntityId,
          ),
        )
        .toList(growable: false);
  }

  static Map<int, List<Id>> tagIdsFromCategoriesByEntity(
    Map<int, List<Category>> categoriesByEntityId,
  ) {
    return <int, List<Id>>{
      for (final MapEntry<int, List<Category>> entry
          in categoriesByEntityId.entries)
        entry.key: entry.value.map((Category c) => c.id).toList(growable: false),
    };
  }
}
