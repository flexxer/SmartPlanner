import 'package:isar_community/isar.dart';

part 'category.g.dart';

/// User-defined tag for tasks, calendar events, and payments.
@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  int colorValue = 0xFF5C6BC0;

  int sortOrder = 0;

  bool isArchived = false;

  DateTime updatedAt = DateTime.now();

  Category();

  factory Category.create({
    required String name,
    int colorValue = 0xFF5C6BC0,
    int sortOrder = 0,
  }) {
    return Category()
      ..name = name
      ..colorValue = colorValue
      ..sortOrder = sortOrder
      ..updatedAt = DateTime.now();
  }
}
