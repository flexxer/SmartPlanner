import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_planner/features/categories/presentation/widgets/category_form_sheet.dart';

/// Category CRUD tab on [LibraryPage].
class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  CategoriesTabState createState() => CategoriesTabState();
}

class CategoriesTabState extends State<CategoriesTab> {
  List<Category> _categories = <Category>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final CategoryRepository repository = context.read<CategoryRepository>();
    final List<Category> list = await repository.getActive();
    if (!mounted) {
      return;
    }
    setState(() {
      _categories = list;
      _loading = false;
    });
  }

  Future<void> createNew() => _openForm();

  Future<void> _openForm({Category? category}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(categoryToEdit: category),
    );
    if (saved == true && mounted) {
      await reload();
    }
  }

  Future<void> _delete(Category category) async {
    final CategoryRepository repository = context.read<CategoryRepository>();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            linkCount > 0
                ? 'category_archived'.tr()
                : 'category_deleted'.tr(),
          ),
        ),
      );
      await reload();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Category item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });
    context.read<CategoryRepository>().reorder(
      _categories.map((Category c) => c.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_categories.isEmpty) {
      return _EmptyCategoriesBody(onCreate: () => _openForm());
    }
    return RefreshIndicator(
      onRefresh: reload,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
        buildDefaultDragHandles: false,
        itemCount: _categories.length,
        onReorder: _onReorder,
        itemBuilder: (BuildContext context, int index) {
          final Category category = _categories[index];
          return _CategoryTile(
            key: ValueKey<Id>(category.id),
            index: index,
            category: category,
            onTap: () => _openForm(category: category),
            onEdit: () => _openForm(category: category),
            onDelete: () => _delete(category),
          );
        },
      ),
    );
  }
}

class _EmptyCategoriesBody extends StatelessWidget {
  const _EmptyCategoriesBody({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.label_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'category_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'category_empty_body'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text('category_new'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required super.key,
    required this.index,
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      leading: ReorderableDragStartListener(
        index: index,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Color(category.colorValue),
        ),
      ),
      title: Text(category.name),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'edit',
            child: Text('common_edit'.tr()),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Text('common_delete'.tr()),
          ),
        ],
      ),
    );
  }
}
