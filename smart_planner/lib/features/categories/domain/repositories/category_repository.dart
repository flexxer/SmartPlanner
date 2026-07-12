import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';

/// Persistence contract for user-defined [Category] tags.
abstract class CategoryRepository {
  Future<List<Category>> getAll({bool includeArchived = false});

  Future<List<Category>> getActive();

  Future<Category?> getById(Id id);

  Future<int> countLinks(Id categoryId);

  Future<int> nextSortOrder();

  Future<Id> save(Category category);

  Future<void> delete(Id id);

  Future<void> archive(Id id);

  Future<void> reorder(List<Id> orderedIds);
}
