import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/categories/data/category_repository_impl.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/entities/category_link.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';

/// Assigns and reads category tags on tasks, events, and payments.
class CategoryTagService {
  CategoryTagService({
    CategoryRepository? categoryRepository,
    Isar? isar,
  })  : _categoryRepository = categoryRepository ?? CategoryRepositoryImpl(isar: isar),
        _isar = isar;

  final CategoryRepository _categoryRepository;
  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<Category>> getTags({
    required TaggedEntityType entityType,
    required int entityId,
  }) async {
    final List<CategoryLink> links = await _db.categoryLinks
        .filter()
        .entityTypeEqualTo(entityType)
        .entityIdEqualTo(entityId)
        .findAll();

    if (links.isEmpty) {
      return const <Category>[];
    }

    final List<Category> categories = <Category>[];
    for (final CategoryLink link in links) {
      final Category? category = await _categoryRepository.getById(link.categoryId);
      if (category != null && !category.isArchived) {
        categories.add(category);
      }
    }
    categories.sort(
      (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
    );
    return categories;
  }

  Future<List<Id>> getTagIds({
    required TaggedEntityType entityType,
    required int entityId,
  }) async {
    final List<CategoryLink> links = await _db.categoryLinks
        .filter()
        .entityTypeEqualTo(entityType)
        .entityIdEqualTo(entityId)
        .findAll();
    return links.map((CategoryLink link) => link.categoryId).toList();
  }

  /// Batch-load category tags for many entities (single link query + one category fetch).
  Future<Map<int, List<Category>>> getTagsForEntities({
    required TaggedEntityType entityType,
    required Iterable<int> entityIds,
  }) async {
    final Set<int> idSet = entityIds.toSet();
    if (idSet.isEmpty) {
      return const <int, List<Category>>{};
    }

    final List<CategoryLink> links = await _db.categoryLinks
        .filter()
        .entityTypeEqualTo(entityType)
        .findAll();

    final List<Category> activeCategories =
        await _categoryRepository.getActive();
    final Map<Id, Category> categoriesById = <Id, Category>{
      for (final Category category in activeCategories) category.id: category,
    };

    final Map<int, List<Category>> result = <int, List<Category>>{};
    for (final CategoryLink link in links) {
      if (!idSet.contains(link.entityId)) {
        continue;
      }
      final Category? category = categoriesById[link.categoryId];
      if (category == null) {
        continue;
      }
      result.putIfAbsent(link.entityId, () => <Category>[]).add(category);
    }

    for (final List<Category> categories in result.values) {
      categories.sort(
        (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
      );
    }
    return result;
  }

  /// Tag ids keyed by entity id (for filtering without loading full [Category] rows).
  Future<Map<int, List<Id>>> getTagIdsForEntities({
    required TaggedEntityType entityType,
    required Iterable<int> entityIds,
  }) async {
    final Map<int, List<Category>> tags = await getTagsForEntities(
      entityType: entityType,
      entityIds: entityIds,
    );
    return <int, List<Id>>{
      for (final MapEntry<int, List<Category>> entry in tags.entries)
        entry.key: entry.value.map((Category c) => c.id).toList(growable: false),
    };
  }

  Future<void> setTags({
    required TaggedEntityType entityType,
    required int entityId,
    required List<Id> categoryIds,
  }) async {
    final Set<Id> uniqueIds = categoryIds.toSet();

    await _db.writeTxn(() async {
      final List<CategoryLink> existing = await _db.categoryLinks
          .filter()
          .entityTypeEqualTo(entityType)
          .entityIdEqualTo(entityId)
          .findAll();

      final Set<Id> existingIds =
          existing.map((CategoryLink link) => link.categoryId).toSet();

      for (final CategoryLink link in existing) {
        if (!uniqueIds.contains(link.categoryId)) {
          await _db.categoryLinks.delete(link.id);
        }
      }

      for (final Id categoryId in uniqueIds) {
        if (existingIds.contains(categoryId)) {
          continue;
        }
        await _db.categoryLinks.put(
          CategoryLink.create(
            entityType: entityType,
            entityId: entityId,
            categoryId: categoryId,
          ),
        );
      }
    });
  }

  Future<void> copyFromEntity({
    required TaggedEntityType fromType,
    required int fromId,
    required TaggedEntityType toType,
    required int toId,
  }) async {
    final List<Id> tagIds = await getTagIds(
      entityType: fromType,
      entityId: fromId,
    );
    await setTags(
      entityType: toType,
      entityId: toId,
      categoryIds: tagIds,
    );
  }

  Future<void> deleteLinksForEntity({
    required TaggedEntityType entityType,
    required int entityId,
  }) async {
    await _db.writeTxn(() async {
      await _db.categoryLinks
          .filter()
          .entityTypeEqualTo(entityType)
          .entityIdEqualTo(entityId)
          .deleteAll();
    });
  }
}
