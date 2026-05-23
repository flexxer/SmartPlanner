import 'package:isar/isar.dart';

part 'task_category.g.dart';

/// Категория задачи (Работа, Дом, Хобби и т.д., PRD §3.2).
@collection
class TaskCategory {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  /// Цвет в формате `#RRGGBB` или `RRGGBB`.
  late String colorHex;

  /// Имя иконки Material (`Icons.*`) или кастомного набора.
  late String iconName;

  TaskCategory();

  TaskCategory.create({
    required this.name,
    required this.colorHex,
    required this.iconName,
  });
}
