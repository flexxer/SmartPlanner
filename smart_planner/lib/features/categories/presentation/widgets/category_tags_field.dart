import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/theme/app_color_utils.dart';
import 'package:smart_planner/features/categories/domain/category_color.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_planner/features/templates/presentation/pages/library_page.dart';

/// Multi-select category tags for task, event, and payment forms.
class CategoryTagsField extends StatefulWidget {
  const CategoryTagsField({
    required this.selectedCategoryIds,
    required this.onSelectionChanged,
    super.key,
  });

  final List<Id> selectedCategoryIds;
  final ValueChanged<List<Id>> onSelectionChanged;

  @override
  State<CategoryTagsField> createState() => _CategoryTagsFieldState();
}

class _CategoryTagsFieldState extends State<CategoryTagsField> {
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

  Future<void> _openLibrary() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LibraryPage(initialTabIndex: 2),
      ),
    );
    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (_loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'category_field_tags'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: _openLibrary,
              child: Text('category_tags_manage'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_available.isEmpty)
          Text(
            'category_tags_empty_hint'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _available.map((Category category) {
              final bool selected =
                  widget.selectedCategoryIds.contains(category.id);
              final Color accent = categoryColorFromValue(category.colorValue);
              final ({Color background, Color foreground}) chipColors =
                  AppColorUtils.chipFromAccent(accent, colors);

              return FilterChip(
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
                  color: selected
                      ? chipColors.foreground
                      : colors.onSurface,
                ),
                side: BorderSide(
                  color: selected
                      ? accent.withValues(alpha: 0.5)
                      : colors.outlineVariant,
                ),
                onSelected: (_) => _toggleCategory(category.id),
              );
            }).toList(growable: false),
          ),
      ],
    );
  }
}
