import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';

/// Bottom sheet to pick a [UiTemplate] for a new task.
class TemplatePickerSheet extends StatefulWidget {
  const TemplatePickerSheet({super.key});

  static Future<UiTemplate?> show(BuildContext context) {
    return showModalBottomSheet<UiTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => const TemplatePickerSheet(),
    );
  }

  @override
  State<TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<TemplatePickerSheet> {
  bool _loading = true;
  List<UiTemplate> _templates = <UiTemplate>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final double maxListHeight = MediaQuery.sizeOf(context).height * 0.45;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'task_relation_templates_title'.tr(),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_templates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'task_relation_templates_empty'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _templates.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final UiTemplate template = _templates[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.outlineVariant),
                      ),
                      title: Text(template.title),
                      subtitle:
                          template.templateDescription?.trim().isNotEmpty ==
                                  true
                              ? Text(template.templateDescription!.trim())
                              : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pop(template),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
