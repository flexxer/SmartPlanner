import 'package:flutter/material.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/presentation/widgets/category_badge_chip.dart';

/// Row of user category tags (distinct from device calendar context badges).
class CategoryBadgesRow extends StatelessWidget {
  const CategoryBadgesRow({
    required this.categories,
    super.key,
  });

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: categories
          .map(
            (Category category) => CategoryBadgeChip(category: category),
          )
          .toList(growable: false),
    );
  }
}
