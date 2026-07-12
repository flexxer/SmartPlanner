import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/theme/app_theme.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/templates/domain/ui_template_embedded_attachment_codec.dart';
import 'package:smart_planner/features/templates/presentation/widgets/template_form_sheet.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Task blueprint templates tab on [LibraryPage].
class TaskTemplatesTab extends StatefulWidget {
  const TaskTemplatesTab({super.key});

  @override
  TaskTemplatesTabState createState() => TaskTemplatesTabState();
}

class TaskTemplatesTabState extends State<TaskTemplatesTab> {
  List<UiTemplate> _templates = <UiTemplate>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final UiTemplateRepository repository =
        context.read<UiTemplateRepository>();
    final List<UiTemplate> list = await repository.getAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Future<void> createNew() => _openForm();

  Future<void> _openForm({UiTemplate? template}) async {
    final UiTemplateRepository repository =
        context.read<UiTemplateRepository>();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => TemplateFormSheet(
        repository: repository,
        templateToEdit: template,
      ),
    );
    if (saved == true && mounted) {
      await reload();
    }
  }

  Future<void> _applyTemplate(UiTemplate template) async {
    final DashboardState blocState = context.read<DashboardBloc>().state;
    final List<String> selectedCalendarIds = blocState is DashboardLoaded
        ? blocState.selectedCalendarIds
        : const <String>[];

    await DashboardScreen.openTaskFormSheet(
      context,
      templateToApply: template,
      selectedCalendarIds: selectedCalendarIds,
    );
  }

  Future<void> _confirmDelete(UiTemplate template) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text('templates_delete_title'.tr()),
          content: Text(
            'templates_delete_body'.tr(
              namedArgs: <String, String>{'title': template.title},
            ),
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
              child: Text('common_delete'.tr()),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<UiTemplateRepository>().delete(template.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('templates_deleted'.tr())),
      );
      await reload();
    }
  }

  String _subtitleFor(UiTemplate template) {
    final List<String> parts = <String>[];
    final String? description = template.templateDescription?.trim();
    if (description != null && description.isNotEmpty) {
      parts.add(description);
    }
    final int checklistCount = template.checklistItems.length;
    if (checklistCount > 0) {
      parts.add(
        'templates_checklist_count'.plural(
          checklistCount,
          namedArgs: <String, String>{'count': '$checklistCount'},
        ),
      );
    }
    final UiTemplateEmbeddedAttachment? embedded =
        UiTemplateEmbeddedAttachmentCodec.decode(
      template.embeddedAttachmentJson,
    );
    if (embedded != null) {
      parts.add(_embeddedLabel(embedded.type));
    }
    if (parts.isEmpty) {
      return 'templates_no_attachments'.tr();
    }
    return parts.join(' · ');
  }

  static String _embeddedLabel(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.location => 'template_attachment_location'.tr(),
      TaskAttachmentType.url => 'template_attachment_url'.tr(),
      TaskAttachmentType.note => 'template_attachment_note'.tr(),
      _ => 'template_attachment_generic'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_templates.isEmpty) {
      return _EmptyTaskTemplatesBody(onCreate: () => _openForm());
    }
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _templates.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final UiTemplate template = _templates[index];
          return _TaskTemplateListTile(
            template: template,
            subtitle: _subtitleFor(template),
            onApply: () => _applyTemplate(template),
            onEdit: () => _openForm(template: template),
            onDelete: () => _confirmDelete(template),
          );
        },
      ),
    );
  }
}

class _EmptyTaskTemplatesBody extends StatelessWidget {
  const _EmptyTaskTemplatesBody({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.task_alt_outlined,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'templates_empty_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'templates_empty_body'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text('templates_create'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTemplateListTile extends StatelessWidget {
  const _TaskTemplateListTile({
    required this.template,
    required this.subtitle,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
  });

  final UiTemplate template;
  final String subtitle;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.insetCardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onApply,
              child: Text('common_apply'.tr()),
            ),
            PopupMenuButton<String>(
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
          ],
        ),
      ),
    );
  }
}
