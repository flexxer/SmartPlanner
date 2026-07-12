import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/entities/category_link.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';

/// Isar-backed [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  @override
  Future<List<Category>> getAll({bool includeArchived = false}) async {
    final List<Category> list = await _db.categorys.where().findAll();
    final List<Category> filtered = includeArchived
        ? list
        : list.where((Category c) => !c.isArchived).toList();
    filtered.sort(
      (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
    );
    return filtered;
  }

  @override
  Future<List<Category>> getActive() => getAll();

  @override
  Future<Category?> getById(Id id) => _db.categorys.get(id);

  @override
  Future<int> countLinks(Id categoryId) async {
    return _db.categoryLinks
        .filter()
        .categoryIdEqualTo(categoryId)
        .count();
  }

  @override
  Future<int> nextSortOrder() async {
    final List<Category> existing = await getAll(includeArchived: true);
    if (existing.isEmpty) {
      return 0;
    }
    return existing.last.sortOrder + 1;
  }

  @override
  Future<Id> save(Category category) async {
    category.updatedAt = DateTime.now();
    return _db.writeTxn(() => _db.categorys.put(category));
  }

  @override
  Future<void> delete(Id id) => _db.writeTxn(() async {
        await _db.categoryLinks
            .filter()
            .categoryIdEqualTo(id)
            .deleteAll();
        await _db.categorys.delete(id);
      });

  @override
  Future<void> archive(Id id) async {
    final Category? category = await getById(id);
    if (category == null) {
      return;
    }
    category.isArchived = true;
    category.updatedAt = DateTime.now();
    await save(category);
  }

  @override
  Future<void> reorder(List<Id> orderedIds) async {
    await _db.writeTxn(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        final Category? category = await _db.categorys.get(orderedIds[i]);
        if (category == null) {
          continue;
        }
        category.sortOrder = i;
        category.updatedAt = DateTime.now();
        await _db.categorys.put(category);
      }
    });
  }
}
