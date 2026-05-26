import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/templates/data/repositories/ui_template_repository.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';

/// Bottom sheet to create or edit a [UiTemplate].
class TemplateFormSheet extends StatefulWidget {
  const TemplateFormSheet({
    required this.repository,
    this.templateToEdit,
    super.key,
  });

  final UiTemplateRepository repository;
  final UiTemplate? templateToEdit;

  bool get isEditing => templateToEdit != null;

  @override
  State<TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<TemplateFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _checklistController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final UiTemplate? existing = widget.templateToEdit;
    if (existing != null) {
      _titleController = TextEditingController(text: existing.title);
      _descriptionController = TextEditingController(
        text: existing.templateDescription ?? '',
      );
      _checklistController = TextEditingController(
        text: existing.checklistItems.join('\n'),
      );
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _checklistController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  List<String> _parseChecklistLines() {
    return _checklistController.text
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('template_enter_name'.tr())),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final String? description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final List<String> checklistItems = _parseChecklistLines();

      if (widget.isEditing) {
        final UiTemplate template = widget.templateToEdit!
          ..title = title
          ..templateDescription = description
          ..checklistItems = checklistItems;
        await widget.repository.save(template);
      } else {
        await widget.repository.save(
          UiTemplate.create(
            title: title,
            templateDescription: description,
            checklistItems: checklistItems,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'common_error_with_details'.tr(namedArgs: <String, String>{
                'details': '$e',
              }),
            ),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final bool isEditing = widget.isEditing;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                isEditing ? 'template_edit'.tr() : 'template_new'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'task_field_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'task_field_description_optional'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _checklistController,
                decoration: InputDecoration(
                  labelText: 'template_field_checklist'.tr(),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'common_save'.tr() : 'common_create'.tr(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
