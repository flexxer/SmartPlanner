import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/theme/app_color_utils.dart';
import 'package:smart_planner/features/categories/domain/category_color.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';

/// Horizontal multi-select category chips for dashboard and search filters.
class CategoryFilterChips extends StatefulWidget {
  const CategoryFilterChips({
    required this.selectedCategoryIds,
    required this.onSelectionChanged,
    super.key,
  });

  final List<Id> selectedCategoryIds;
  final ValueChanged<List<Id>> onSelectionChanged;

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  List<Category> _available = <Category>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final CategoryRepository repository = context.read<CategoryRepository>();
    final List<Category> list = await repository.getActive();
    if (!mounted) {
      return;
    }
    setState(() {
      _available = list;
      _loading = false;
    });
  }

  void _toggleCategory(Id categoryId) {
    final Set<Id> next = widget.selectedCategoryIds.toSet();
    if (next.contains(categoryId)) {
      next.remove(categoryId);
    } else {
      next.add(categoryId);
    }
    widget.onSelectionChanged(next.toList(growable: false));
  }

  void _clearSelection() {
    widget.onSelectionChanged(const <Id>[]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_available.isEmpty) {
      return const SizedBox.shrink();
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool hasSelection = widget.selectedCategoryIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'category_filter_label'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (hasSelection)
                TextButton(
                  onPressed: _clearSelection,
                  child: Text('category_filter_clear'.tr()),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: _available.map((Category category) {
              final bool selected =
                  widget.selectedCategoryIds.contains(category.id);
              final Color accent = categoryColorFromValue(category.colorValue);
              final ({Color background, Color foreground}) chipColors =
                  AppColorUtils.chipFromAccent(accent, colors);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.name),
                  selected: selected,
                  showCheckmark: true,
                  avatar: CircleAvatar(
                    radius: 8,
                    backgroundColor: accent,
                  ),
                  selectedColor: chipColors.background,
                  checkmarkColor: chipColors.foreground,
                  labelStyle: TextStyle(
                    color: selected ? chipColors.foreground : colors.onSurface,
                  ),
                  side: BorderSide(
                    color: selected
                        ? accent.withValues(alpha: 0.5)
                        : colors.outlineVariant,
                  ),
                  onSelected: (_) => _toggleCategory(category.id),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}
