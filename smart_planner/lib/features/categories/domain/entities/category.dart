/// User-defined tag for tasks, calendar events, and payments.
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `CategoryModel` in the data layer.
class Category {
  Category({this.id = 0});

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

  /// Database id; `0` until persisted.
  int id;

  String name = '';

  int colorValue = 0xFF5C6BC0;

  int sortOrder = 0;

  bool isArchived = false;

  DateTime updatedAt = DateTime.now();
}
