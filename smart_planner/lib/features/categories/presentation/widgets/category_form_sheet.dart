import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/presentation/widgets/form_sheet_scaffold.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';

/// Preset accent colors for new categories.
const List<int> categoryColorPresets = <int>[
  0xFF5C6BC0,
  0xFF26A69A,
  0xFFEF5350,
  0xFFFF7043,
  0xFFAB47BC,
  0xFF42A5F5,
  0xFF8D6E63,
  0xFF78909C,
];

/// Bottom sheet to create or edit a [Category].
class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({
    this.categoryToEdit,
    super.key,
  });

  final Category? categoryToEdit;

  bool get isEditing => categoryToEdit != null;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late int _colorValue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Category? existing = widget.categoryToEdit;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _colorValue = existing?.colorValue ?? categoryColorPresets.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('category_enter_name'.tr())),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final CategoryRepository repository =
          context.read<CategoryRepository>();

      if (widget.isEditing) {
        final Category category = widget.categoryToEdit!
          ..name = name
          ..colorValue = _colorValue;
        await repository.save(category);
      } else {
        final int sortOrder = await repository.nextSortOrder();
        await repository.save(
          Category.create(
            name: name,
            colorValue: _colorValue,
            sortOrder: sortOrder,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common_error_generic'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final CategoryRepository repository =
        context.read<CategoryRepository>();
    final Category category = widget.categoryToEdit!;
    final int linkCount = await repository.countLinks(category.id);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;
        final String titleKey = linkCount > 0
            ? 'category_archive_title'
            : 'category_delete_title';
        final String bodyKey = linkCount > 0
            ? 'category_archive_body'
            : 'category_delete_body';
        return AlertDialog(
          title: Text(titleKey.tr()),
          content: Text(
            bodyKey.tr(namedArgs: <String, String>{'name': category.name}),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('common_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: Text(
                linkCount > 0
                    ? 'category_archive_action'.tr()
                    : 'common_delete'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    if (linkCount > 0) {
      await repository.archive(category.id);
    } else {
      await repository.delete(category.id);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: widget.isEditing
          ? 'category_edit'.tr()
          : 'category_new'.tr(),
      onDelete: widget.isEditing ? _confirmDelete : null,
      children: <Widget>[
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'category_field_name'.tr(),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          autofocus: !widget.isEditing,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        Text(
          'category_field_color'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categoryColorPresets.map((int color) {
            final bool selected = _colorValue == color;
            return InkWell(
              onTap: () => setState(() => _colorValue = color),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Color(color),
                child: selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        FormSheetSaveButton(
          label: 'common_save'.tr(),
          onPressed: _saving ? null : _save,
          enabled: !_saving,
        ),
      ],
    );
  }
}
