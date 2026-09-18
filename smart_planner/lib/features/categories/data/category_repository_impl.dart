import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/categories/data/models/category_link_model.dart';
import 'package:smart_planner/features/categories/data/models/category_model.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';

/// Isar-backed [CategoryRepository]. Maps between the pure domain entity and
/// the [CategoryModel] persistence row, and reports failures as [Result].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({this.isar});

  final Isar? isar;

  Isar get _db => isar ?? IsarDatabase.instance;

  @override
  Future<Result<List<Category>>> getAll({bool includeArchived = false}) async {
    try {
      final List<CategoryModel> list =
          await _db.categoryModels.where().findAll();
      final List<Category> filtered = includeArchived
          ? list.map((CategoryModel m) => m.toDomain()).toList()
          : list
              .where((CategoryModel m) => !m.isArchived)
              .map((CategoryModel m) => m.toDomain())
              .toList();
      filtered.sort(
        (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
      );
      return Success(filtered);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load categories: $error', stackTrace),
      );
    }
  }

  @override
  Future<Result<List<Category>>> getActive() => getAll();

  @override
  Future<Result<Category?>> getById(int id) async {
    try {
      final CategoryModel? model = await _db.categoryModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to load category $id: $error', stackTrace),
      );
    }
  }

  @override
  Future<Result<int>> countLinks(int categoryId) async {
    try {
      final int count = await _db.categoryLinkModels
          .filter()
          .categoryIdEqualTo(categoryId)
          .count();
      return Success(count);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to count category links: $error', stackTrace),
      );
    }
  }

  @override
  Future<Result<int>> nextSortOrder() async {
    final Result<List<Category>> result = await getAll(includeArchived: true);
    return result.map(
      (List<Category> list) => list.isEmpty ? 0 : list.last.sortOrder + 1,
    );
  }

  @override
  Future<Result<Category>> save(Category category) async {
    try {
      category.updatedAt = DateTime.now();
      final CategoryModel model = CategoryModel.fromDomain(category);
      await _db.writeTxn(() => _db.categoryModels.put(model));
      return Success(model.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to save category: $error', stackTrace),
      );
    }
  }

  @override
  Future<Result<bool>> delete(int id) async {
    try {
      await _db.writeTxn(() async {
        await _db.categoryLinkModels
            .filter()
            .categoryIdEqualTo(id)
            .deleteAll();
        await _db.categoryModels.delete(id);
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to delete category $id: $error', stackTrace),
      );
    }
  }

  @override
  Future<Result<bool>> archive(int id) async {
    final Category? category = (await getById(id)).getOrElse((_) => null);
    if (category == null) {
      return const Success(false);
    }
    category.isArchived = true;
    category.updatedAt = DateTime.now();
    final Result<Category> saved = await save(category);
    return saved.map((Category _) => true);
  }

  @override
  Future<Result<bool>> reorder(List<int> orderedIds) async {
    try {
      await _db.writeTxn(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          final CategoryModel? model =
              await _db.categoryModels.get(orderedIds[i]);
          if (model == null) {
            continue;
          }
          model.sortOrder = i;
          model.updatedAt = DateTime.now();
          await _db.categoryModels.put(model);
        }
      });
      return const Success(true);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to reorder categories: $error', stackTrace),
      );
    }
  }
}
