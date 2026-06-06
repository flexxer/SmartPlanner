import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/attachment_templates/data/repositories/attachment_template_repository.dart';
import 'package:smart_planner/features/attachment_templates/domain/attachment_template_labels.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/todo_list/data/services/osm_place_search_service.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/checklist_editor_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/location_map_picker_sheet.dart';

/// Create or edit an [AttachmentTemplate].
class AttachmentTemplateFormSheet extends StatefulWidget {
  const AttachmentTemplateFormSheet({
    this.templateToEdit,
    this.copyFrom,
    super.key,
  });

  final AttachmentTemplate? templateToEdit;
  final AttachmentTemplate? copyFrom;

  @override
  State<AttachmentTemplateFormSheet> createState() =>
      _AttachmentTemplateFormSheetState();
}

class _AttachmentTemplateFormSheetState extends State<AttachmentTemplateFormSheet> {
  late final TextEditingController _titleController;
  late TaskAttachmentType _type;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _urlTitleController = TextEditingController();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteBodyController = TextEditingController();
  final TextEditingController _checklistTitleController = TextEditingController();
  final GlobalKey<ChecklistEditorSectionState> _checklistKey =
      GlobalKey<ChecklistEditorSectionState>();
  List<ChecklistItemPayload> _initialChecklistItems = <ChecklistItemPayload>[];
  bool _initialMoveCompletedToEnd = true;
  double? _latitude;
  double? _longitude;
  String? _placeName;
  String? _locationLabel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final AttachmentTemplate? existing = widget.templateToEdit;
    final AttachmentTemplate? copyFrom = widget.copyFrom;
    final AttachmentTemplate? source = existing ?? copyFrom;

    if (copyFrom != null) {
      _titleController = TextEditingController(
        text:
            '${AttachmentTemplateLabels.displayTitle(copyFrom)} '
            '(${AttachmentTemplateLabels.copySuffix()})',
      );
    } else if (existing != null) {
      _titleController = TextEditingController(
        text: AttachmentTemplateLabels.displayTitle(existing),
      );
    } else {
      _titleController = TextEditingController();
    }

    _type = source?.type ?? TaskAttachmentType.location;
    if (source != null && source.payloadJson.isNotEmpty) {
      _prefill(source);
    }
  }

  bool get _typeLocked => widget.templateToEdit != null || widget.copyFrom != null;

  void _prefill(AttachmentTemplate template) {
    final Object? decoded = jsonDecode(template.payloadJson);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    switch (template.type) {
      case TaskAttachmentType.url:
        final UrlAttachmentPayload url = UrlAttachmentPayload.fromJson(decoded);
        _urlController.text = url.url;
        _urlTitleController.text = url.label ?? '';
      case TaskAttachmentType.note:
        final NoteAttachmentPayload note = NoteAttachmentPayload.fromJson(decoded);
        _noteTitleController.text = note.title ?? '';
        _noteBodyController.text = note.body;
      case TaskAttachmentType.checklist:
        final ChecklistAttachmentPayload checklist =
            ChecklistAttachmentPayload.fromJson(decoded);
        _checklistTitleController.text = checklist.title ?? '';
        _initialChecklistItems = List<ChecklistItemPayload>.from(checklist.items);
        _initialMoveCompletedToEnd = checklist.moveCompletedToEnd;
      case TaskAttachmentType.location:
        final LocationAttachmentPayload location =
            LocationAttachmentPayload.fromJson(decoded);
        _latitude = location.latitude;
        _longitude = location.longitude;
        _placeName = location.placeName;
        _locationLabel = location.label;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _urlTitleController.dispose();
    _noteTitleController.dispose();
    _noteBodyController.dispose();
    _checklistTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final LocationPickResult? result = await showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LocationMapPickerSheet(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    String? placeName = result.placeName;
    placeName ??= await OsmPlaceSearchService.reverseGeocode(
      latitude: result.latitude,
      longitude: result.longitude,
    );
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _placeName = placeName;
    });
  }

  String? _buildPayload() {
    return switch (_type) {
      TaskAttachmentType.url => TaskAttachmentCodec.encodeMap(
          UrlAttachmentPayload(
            url: _urlController.text.trim(),
            label: _urlTitleController.text.trim().isEmpty
                ? null
                : _urlTitleController.text.trim(),
          ).toJson(),
        ),
      TaskAttachmentType.note => TaskAttachmentCodec.encodeMap(
          NoteAttachmentPayload(
            title: _noteTitleController.text.trim().isEmpty
                ? null
                : _noteTitleController.text.trim(),
            body: _noteBodyController.text.trim(),
          ).toJson(),
        ),
      TaskAttachmentType.checklist => TaskAttachmentCodec.encodeMap(
          ChecklistAttachmentPayload(
            title: _checklistTitleController.text.trim().isEmpty
                ? null
                : _checklistTitleController.text.trim(),
            items: _checklistKey.currentState?.collectItems() ??
                _initialChecklistItems,
            moveCompletedToEnd:
                _checklistKey.currentState?.moveCompletedToEnd ??
                    _initialMoveCompletedToEnd,
          ).toJson(),
        ),
      TaskAttachmentType.location => _latitude != null && _longitude != null
          ? TaskAttachmentCodec.encodeMap(
              LocationAttachmentPayload(
                latitude: _latitude!,
                longitude: _longitude!,
                placeName: _placeName,
                label: _locationLabel,
              ).toJson(),
            )
          : null,
      _ => null,
    };
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('attachment_template_enter_title'.tr())),
      );
      return;
    }
    final String? payload = _buildPayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('attachment_template_incomplete'.tr())),
      );
      return;
    }

    setState(() => _saving = true);
    final AttachmentTemplateRepository repository =
        context.read<AttachmentTemplateRepository>();
    final AttachmentTemplate? existing = widget.templateToEdit;
    final AttachmentTemplate template = existing ?? AttachmentTemplate.create(
      title: title,
      type: _type,
      payloadJson: payload,
      sortOrder: await repository.nextSortOrder(),
    );
    if (existing != null) {
      template
        ..title = title
        ..type = _type
        ..payloadJson = payload;
    }
    await repository.save(template);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.templateToEdit != null
                    ? 'attachment_template_edit'.tr()
                    : widget.copyFrom != null
                        ? 'attachment_template_duplicate'.tr()
                        : 'attachment_template_new'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'attachment_template_field_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskAttachmentType>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'attachment_select_type'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: <TaskAttachmentType>[
                  TaskAttachmentType.location,
                  TaskAttachmentType.checklist,
                  TaskAttachmentType.url,
                  TaskAttachmentType.note,
                ].map((TaskAttachmentType type) {
                  return DropdownMenuItem<TaskAttachmentType>(
                    value: type,
                    child: Text(_typeLabel(type)),
                  );
                }).toList(),
                onChanged: _typeLocked
                    ? null
                    : (TaskAttachmentType? value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              ..._fieldsForType(),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text('common_save'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _fieldsForType() {
    return switch (_type) {
      TaskAttachmentType.location => <Widget>[
          if (_latitude != null)
            Text(
              _placeName ?? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
            ),
          OutlinedButton.icon(
            onPressed: _pickOnMap,
            icon: const Icon(Icons.map_outlined),
            label: Text('attachment_pick_on_map'.tr()),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (String value) => _locationLabel = value.trim().isEmpty ? null : value.trim(),
            decoration: InputDecoration(
              labelText: 'attachment_field_place_name'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      TaskAttachmentType.url => <Widget>[
          TextField(
            controller: _urlTitleController,
            decoration: InputDecoration(
              labelText: 'attachment_field_title_optional'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      TaskAttachmentType.note => <Widget>[
          TextField(
            controller: _noteTitleController,
            decoration: InputDecoration(
              labelText: 'attachment_field_title_optional'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteBodyController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'attachment_field_text'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      TaskAttachmentType.checklist => <Widget>[
          ChecklistEditorSection(
            key: _checklistKey,
            titleController: _checklistTitleController,
            initialItems: _initialChecklistItems,
            initialMoveCompletedToEnd: _initialMoveCompletedToEnd,
          ),
        ],
      _ => <Widget>[],
    };
  }

  static String _typeLabel(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.location => 'attachment_type_location'.tr(),
      TaskAttachmentType.checklist => 'attachment_type_checklist'.tr(),
      TaskAttachmentType.url => 'attachment_type_url'.tr(),
      TaskAttachmentType.note => 'attachment_type_note'.tr(),
      _ => type.name,
    };
  }
}
