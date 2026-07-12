import 'package:flutter/material.dart';
import 'package:smart_planner/core/theme/app_color_utils.dart';
import 'package:smart_planner/features/categories/domain/category_color.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';

/// Read-only chip for a user-defined [Category] tag.
class CategoryBadgeChip extends StatelessWidget {
  const CategoryBadgeChip({
    required this.category,
    super.key,
  });

  final Category category;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = categoryColorFromValue(category.colorValue);
    final ({Color background, Color foreground}) chipColors =
        AppColorUtils.chipFromAccent(accent, colors);

    return Chip(
      avatar: CircleAvatar(
        radius: 6,
        backgroundColor: accent,
      ),
      label: Text(category.name),
      backgroundColor: chipColors.background,
      labelStyle: TextStyle(color: chipColors.foreground),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
