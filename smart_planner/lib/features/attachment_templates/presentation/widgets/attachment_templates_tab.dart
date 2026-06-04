import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/attachment_templates/data/repositories/attachment_template_repository.dart';
import 'package:smart_planner/features/attachment_templates/domain/attachment_template_factory.dart';
import 'package:smart_planner/features/attachment_templates/domain/attachment_template_labels.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/attachment_templates/presentation/widgets/attachment_template_form_sheet.dart';

/// Attachment preset templates tab on [TemplatesPage].
class AttachmentTemplatesTab extends StatefulWidget {
  const AttachmentTemplatesTab({super.key});

  @override
  AttachmentTemplatesTabState createState() => AttachmentTemplatesTabState();
}

class AttachmentTemplatesTabState extends State<AttachmentTemplatesTab> {
  List<AttachmentTemplate> _templates = <AttachmentTemplate>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final AttachmentTemplateRepository repository =
        context.read<AttachmentTemplateRepository>();
    final List<AttachmentTemplate> list = await repository.getAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Future<void> createNew() => _openForm();

  Future<void> _openForm({
    AttachmentTemplate? templateToEdit,
    AttachmentTemplate? copyFrom,
  }) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AttachmentTemplateFormSheet(
        templateToEdit: templateToEdit,
        copyFrom: copyFrom,
      ),
    );
    if (saved == true && mounted) {
      await reload();
    }
  }

  Future<void> _duplicate(AttachmentTemplate source) async {
    final AttachmentTemplateRepository repository =
        context.read<AttachmentTemplateRepository>();
    final int sortOrder = await repository.nextSortOrder();
    final AttachmentTemplate copy = AttachmentTemplateFactory.duplicate(
      source,
      sortOrder: sortOrder,
    );
    await repository.save(copy);
    await reload();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('attachment_template_duplicated'.tr())),
    );
  }

  Future<void> _delete(AttachmentTemplate template) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('attachment_template_delete_title'.tr()),
            content: Text('attachment_template_delete_body'.tr()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('common_cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('common_delete'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    await context.read<AttachmentTemplateRepository>().delete(template.id);
    await reload();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final AttachmentTemplate item = _templates.removeAt(oldIndex);
      _templates.insert(newIndex, item);
    });
    context.read<AttachmentTemplateRepository>().reorder(
      _templates.map((AttachmentTemplate t) => t.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_templates.isEmpty) {
      return _EmptyAttachmentTemplatesBody(onCreate: () => _openForm());
    }
    return RefreshIndicator(
      onRefresh: reload,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
        buildDefaultDragHandles: false,
        itemCount: _templates.length,
        onReorder: _onReorder,
        itemBuilder: (BuildContext context, int index) {
          final AttachmentTemplate template = _templates[index];
          return _AttachmentTemplateTile(
            key: ValueKey<Id>(template.id),
            index: index,
            template: template,
            onTap: () => _openForm(templateToEdit: template),
            onDuplicate: () => _duplicate(template),
            onEdit: () => _openForm(templateToEdit: template),
            onDelete: () => _delete(template),
          );
        },
      ),
    );
  }
}

class _EmptyAttachmentTemplatesBody extends StatelessWidget {
  const _EmptyAttachmentTemplatesBody({required this.onCreate});

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
              Icons.bookmark_add_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'attachment_templates_empty'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'attachment_templates_empty_hint'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text('attachment_template_new'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTemplateTile extends StatelessWidget {
  const _AttachmentTemplateTile({
    required super.key,
    required this.index,
    required this.template,
    required this.onTap,
    required this.onDuplicate,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final AttachmentTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(AttachmentTemplateLabels.iconFor(template.type)),
      ),
      title: Text(AttachmentTemplateLabels.displayTitle(template)),
      subtitle: Text(AttachmentTemplateLabels.typeLabel(template.type)),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'duplicate':
              onDuplicate();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'edit',
            child: Text('attachment_edit'.tr()),
          ),
          PopupMenuItem<String>(
            value: 'duplicate',
            child: Text('attachment_template_duplicate'.tr()),
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
