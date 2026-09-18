import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';

/// Persistence contract for user-defined [Category] tags.
abstract class CategoryRepository {
  Future<Result<List<Category>>> getAll({bool includeArchived = false});

  Future<Result<List<Category>>> getActive();

  Future<Result<Category?>> getById(int id);

  Future<Result<int>> countLinks(int categoryId);

  Future<Result<int>> nextSortOrder();

  Future<Result<Category>> save(Category category);

  Future<Result<bool>> delete(int id);

  Future<Result<bool>> archive(int id);

  Future<Result<bool>> reorder(List<int> orderedIds);
}
