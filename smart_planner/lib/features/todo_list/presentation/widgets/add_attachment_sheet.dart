import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/data/services/device_contact_picker.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/data/services/osm_place_search_service.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/attachment_templates/data/repositories/attachment_template_repository.dart';
import 'package:smart_planner/features/attachment_templates/domain/attachment_template_applicator.dart';
import 'package:smart_planner/features/attachment_templates/domain/attachment_template_labels.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/attachment_templates/presentation/widgets/attachment_template_form_sheet.dart';
import 'package:smart_planner/features/templates/presentation/pages/templates_page.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/checklist_editor_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/location_map_picker_sheet.dart';

/// Add or edit a local attachment on a task or calendar event.
class AddAttachmentSheet extends StatefulWidget {
  const AddAttachmentSheet({
    required TaskAttachmentRepository repository,
    required Id taskId,
    TaskAttachment? attachmentToEdit,
    DashboardBloc? dashboardBloc,
    super.key,
  })  : taskRepository = repository,
        eventRepository = null,
        taskId = taskId,
        eventId = null,
        taskAttachmentToEdit = attachmentToEdit,
        eventAttachmentToEdit = null,
        dashboardBloc = dashboardBloc;

  const AddAttachmentSheet.forEvent({
    required EventAttachmentRepository repository,
    required Id eventId,
    EventAttachment? attachmentToEdit,
    super.key,
  })  : taskRepository = null,
        eventRepository = repository,
        taskId = null,
        eventId = eventId,
        taskAttachmentToEdit = null,
        eventAttachmentToEdit = attachmentToEdit,
        dashboardBloc = null;

  final TaskAttachmentRepository? taskRepository;
  final EventAttachmentRepository? eventRepository;
  final Id? taskId;
  final Id? eventId;
  final TaskAttachment? taskAttachmentToEdit;
  final EventAttachment? eventAttachmentToEdit;
  final DashboardBloc? dashboardBloc;

  bool get isEditing =>
      taskAttachmentToEdit != null || eventAttachmentToEdit != null;

  bool get isEventMode => eventRepository != null;

  AttachmentFileStore get fileStore =>
      taskRepository?.fileStore ?? eventRepository!.fileStore;

  @override
  State<AddAttachmentSheet> createState() => _AddAttachmentSheetState();
}

class _AddAttachmentSheetState extends State<AddAttachmentSheet> {
  TaskAttachmentType? _selectedType;
  bool _saving = false;
  bool _pickingContact = false;

  ContactAttachmentPayload? _pickedContact;
  final TextEditingController _urlTitleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _locationLabelController = TextEditingController();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteBodyController = TextEditingController();
  final TextEditingController _checklistTitleController = TextEditingController();
  List<ChecklistItemPayload> _initialChecklistItems = <ChecklistItemPayload>[];
  final GlobalKey<ChecklistEditorSectionState> _checklistKey =
      GlobalKey<ChecklistEditorSectionState>();
  List<AttachmentTemplate> _templates = <AttachmentTemplate>[];

  String? _imageRelativePath;
  StoredAttachmentFile? _storedFile;
  double? _latitude;
  double? _longitude;

  /// Nominatim [display_name] from the last map pick or reverse geocode.
  String? _pickedPlaceName;

  @override
  void initState() {
    super.initState();
    final TaskAttachment? taskExisting = widget.taskAttachmentToEdit;
    final EventAttachment? eventExisting = widget.eventAttachmentToEdit;
    if (taskExisting != null) {
      _prefillFromAttachment(AttachmentRef.fromTask(taskExisting));
    } else if (eventExisting != null) {
      _prefillFromAttachment(AttachmentRef.fromEvent(eventExisting));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryReadClipboardUrl();
        _loadTemplates();
      });
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final AttachmentTemplateRepository repository =
          context.read<AttachmentTemplateRepository>();
      final List<AttachmentTemplate> list = await repository.getAll();
      if (mounted) {
        setState(() => _templates = list);
      }
    } on Object {
      // Templates are optional when repository is not provided.
    }
  }

  void _prefillFromAttachment(AttachmentRef attachment) {
    _selectedType = attachment.type;
    switch (attachment.type) {
      case TaskAttachmentType.contact:
        _pickedContact = TaskAttachmentCodec.contactRef(attachment);
      case TaskAttachmentType.image:
        _imageRelativePath =
            TaskAttachmentCodec.imageRef(attachment).relativePath;
      case TaskAttachmentType.file:
        final FileAttachmentPayload file =
            TaskAttachmentCodec.fileRef(attachment);
        _storedFile = StoredAttachmentFile(
          relativePath: file.relativePath,
          fileName: file.fileName,
          mimeType: file.mimeType,
        );
      case TaskAttachmentType.url:
        final UrlAttachmentPayload url = TaskAttachmentCodec.urlRef(attachment);
        _urlController.text = url.url;
        final String label = (url.label ?? '').trim();
        if (label.isNotEmpty && label != url.url) {
          _urlTitleController.text = label;
        }
      case TaskAttachmentType.location:
        final LocationAttachmentPayload location =
            TaskAttachmentCodec.locationRef(attachment);
        _latitude = location.latitude;
        _longitude = location.longitude;
        _pickedPlaceName = location.placeName;
        final String customLabel = location.label?.trim() ?? '';
        if (customLabel.isNotEmpty) {
          _locationLabelController.text = customLabel;
        } else if (location.placeName != null &&
            location.placeName!.trim().isNotEmpty) {
          _locationLabelController.text = location.placeName!.trim();
        }
      case TaskAttachmentType.note:
        final NoteAttachmentPayload note =
            TaskAttachmentCodec.noteRef(attachment);
        final String? title = note.title?.trim();
        if (title != null && title.isNotEmpty) {
          _noteTitleController.text = title;
        }
        _noteBodyController.text = note.body;
      case TaskAttachmentType.checklist:
        final ChecklistAttachmentPayload checklist =
            TaskAttachmentCodec.checklistRef(attachment);
        final String? title = checklist.title?.trim();
        if (title != null && title.isNotEmpty) {
          _checklistTitleController.text = title;
        }
        _initialChecklistItems = List<ChecklistItemPayload>.from(checklist.items);
    }
  }

  Future<void> _tryReadClipboardUrl() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) {
      return;
    }
    if (_isValidUrl(text)) {
      setState(() => _urlController.text = text);
    }
  }

  static bool _isValidUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static String? _domainFromUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    return uri.host;
  }

  @override
  void dispose() {
    _urlTitleController.dispose();
    _urlController.dispose();
    _locationLabelController.dispose();
    _noteTitleController.dispose();
    _noteBodyController.dispose();
    _checklistTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final StoredAttachmentFile? picked =
        await widget.fileStore.pickAndStoreFile();
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedType = TaskAttachmentType.file;
      _storedFile = picked;
    });
    await _save();
  }

  Future<void> _pickImage() async {
    final String? path = await widget.fileStore.pickAndStoreImage();
    if (path == null || !mounted) {
      return;
    }
    setState(() {
      _selectedType = TaskAttachmentType.image;
      _imageRelativePath = path;
    });
    await _save();
  }

  Future<void> _pickContactSystem() async {
    setState(() => _pickingContact = true);
    try {
      final DeviceContactPickResult result =
          await DeviceContactPicker.pickSystem();
      if (!mounted) {
        return;
      }
      switch (result.outcome) {
        case DeviceContactPickOutcome.cancelled:
          return;
        case DeviceContactPickOutcome.picked:
          setState(() => _pickedContact = result.payload);
        case DeviceContactPickOutcome.failed:
          _showError('attachment_contacts_failed'.tr());
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'common_error_with_details'.tr(
            namedArgs: <String, String>{'details': '$e'},
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pickingContact = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('attachment_location_disabled'.tr());
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError('attachment_location_denied'.tr());
      return;
    }
    final Position position = await Geolocator.getCurrentPosition();
    final String? placeName = await OsmPlaceSearchService.reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _pickedPlaceName = placeName;
      if (placeName != null &&
          placeName.isNotEmpty &&
          _locationLabelController.text.trim().isEmpty) {
        _locationLabelController.text = placeName;
      }
    });
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

    String? placeName = result.placeName?.trim();
    if (placeName == null || placeName.isEmpty) {
      placeName = await OsmPlaceSearchService.reverseGeocode(
        latitude: result.latitude,
        longitude: result.longitude,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _pickedPlaceName = placeName;
      if (_locationLabelController.text.trim().isEmpty &&
          placeName != null &&
          placeName.isNotEmpty) {
        _locationLabelController.text = placeName;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<ChecklistItemPayload> _checklistItemsForSave() =>
      _checklistKey.currentState?.collectItems() ?? _initialChecklistItems;

  Future<void> _openNewTemplateForm() async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AttachmentTemplateFormSheet(),
    );
    if (saved == true) {
      await _loadTemplates();
    }
  }

  Future<void> _showTemplateMenu(AttachmentTemplate template) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(AttachmentTemplateLabels.displayTitle(template)),
              subtitle: Text(AttachmentTemplateLabels.typeLabel(template.type)),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow_outlined),
              title: Text('attachment_template_apply'.tr()),
              onTap: () => Navigator.pop(sheetContext, 'apply'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('attachment_edit'.tr()),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text('attachment_template_duplicate'.tr()),
              onTap: () => Navigator.pop(sheetContext, 'duplicate'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case 'apply':
        await _applyTemplate(template);
      case 'edit':
        final bool? saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              AttachmentTemplateFormSheet(templateToEdit: template),
        );
        if (saved == true) {
          await _loadTemplates();
        }
      case 'duplicate':
        final bool? saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => AttachmentTemplateFormSheet(copyFrom: template),
        );
        if (saved == true) {
          await _loadTemplates();
        }
    }
  }

  Future<void> _applyTemplate(AttachmentTemplate template) async {
    if (!attachmentTemplateIsReady(template)) {
      if (template.type == TaskAttachmentType.location) {
        await _configureLocationTemplate(template);
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final bool applied = widget.isEventMode
          ? await AttachmentTemplateApplicator.applyToEvent(
              template: template,
              eventId: widget.eventId!,
              repository: widget.eventRepository!,
            )
          : await AttachmentTemplateApplicator.applyToTask(
              template: template,
              taskId: widget.taskId!,
              repository: widget.taskRepository!,
            );
      if (applied && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _configureLocationTemplate(AttachmentTemplate template) async {
    final LocationPickResult? result = await showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LocationMapPickerSheet(),
    );
    if (result == null || !mounted) {
      return;
    }
    String? placeName = result.placeName;
    placeName ??= await OsmPlaceSearchService.reverseGeocode(
      latitude: result.latitude,
      longitude: result.longitude,
    );
    final String label = AttachmentTemplateLabels.displayTitle(template);
    final String payload = TaskAttachmentCodec.encodeMap(
      LocationAttachmentPayload(
        latitude: result.latitude,
        longitude: result.longitude,
        placeName: placeName,
        label: label,
      ).toJson(),
    );
    template.payloadJson = payload;
    try {
      await context.read<AttachmentTemplateRepository>().save(template);
    } on Object {
      // Continue even if template save fails.
    }
    await _applyTemplate(template);
  }

  Future<void> _save() async {
    final TaskAttachmentType? type = _selectedType;
    if (type == null) {
      _showError('attachment_select_type'.tr());
      return;
    }

    final String? payloadJson = switch (type) {
      TaskAttachmentType.contact => _encodeContact(),
      TaskAttachmentType.image => _encodeImage(),
      TaskAttachmentType.file => _encodeFile(),
      TaskAttachmentType.url => _encodeUrl(),
      TaskAttachmentType.location => _encodeLocation(),
      TaskAttachmentType.note => _encodeNote(),
      TaskAttachmentType.checklist => _encodeChecklist(),
    };

    if (payloadJson == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final String? attachmentLabel = switch (type) {
        TaskAttachmentType.location => _locationAttachmentLabel(),
        TaskAttachmentType.url => _urlAttachmentLabel(),
        TaskAttachmentType.note => _noteAttachmentLabel(),
        TaskAttachmentType.checklist =>
          _checklistTitleController.text.trim().isEmpty
              ? null
              : _checklistTitleController.text.trim(),
        _ => null,
      };

      if (widget.isEditing) {
        await _saveEdit(
          type: type,
          payloadJson: payloadJson,
          attachmentLabel: attachmentLabel,
        );
      } else {
        await _saveCreate(
          type: type,
          payloadJson: payloadJson,
          attachmentLabel: attachmentLabel,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'common_error_with_details'.tr(
            namedArgs: <String, String>{'details': '$e'},
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  String? _encodeContact() {
    final ContactAttachmentPayload? contact = _pickedContact;
    if (contact == null) {
      _showError('attachment_select_contact'.tr());
      return null;
    }
    return TaskAttachmentCodec.encodeMap(contact.toJson());
  }

  Future<void> _saveEdit({
    required TaskAttachmentType type,
    required String payloadJson,
    required String? attachmentLabel,
  }) async {
    if (widget.isEventMode) {
      final EventAttachment attachment = widget.eventAttachmentToEdit!
        ..payloadJson = payloadJson
        ..label = attachmentLabel;
      await widget.eventRepository!.update(attachment);
      return;
    }
    final TaskAttachment attachment = widget.taskAttachmentToEdit!
      ..payloadJson = payloadJson
      ..label = attachmentLabel;
    final DashboardBloc? bloc = widget.dashboardBloc;
    if (bloc != null) {
      bloc.add(UpdateTaskAttachment(attachment));
    } else {
      await widget.taskRepository!.update(attachment);
    }
  }

  Future<void> _saveCreate({
    required TaskAttachmentType type,
    required String payloadJson,
    required String? attachmentLabel,
  }) async {
    if (widget.isEventMode) {
      final int sortOrder =
          await widget.eventRepository!.nextSortOrder(widget.eventId!);
      await widget.eventRepository!.save(
        EventAttachment.create(
          eventId: widget.eventId!,
          type: type,
          payloadJson: payloadJson,
          label: attachmentLabel,
          sortOrder: sortOrder,
        ),
      );
      return;
    }
    final int sortOrder =
        await widget.taskRepository!.nextSortOrder(widget.taskId!);
    await widget.taskRepository!.save(
      TaskAttachment.create(
        taskId: widget.taskId!,
        type: type,
        payloadJson: payloadJson,
        label: attachmentLabel,
        sortOrder: sortOrder,
      ),
    );
  }

  String? _encodeFile() {
    final StoredAttachmentFile? file = _storedFile;
    if (file == null) {
      _showError('attachment_select_file'.tr());
      return null;
    }
    return TaskAttachmentCodec.encodeMap(
      FileAttachmentPayload(
        relativePath: file.relativePath,
        fileName: file.fileName,
        mimeType: file.mimeType,
      ).toJson(),
    );
  }

  String? _encodeImage() {
    if (_imageRelativePath == null) {
      _showError('attachment_select_image'.tr());
      return null;
    }
    return TaskAttachmentCodec.encodeMap(
      ImageAttachmentPayload(relativePath: _imageRelativePath!).toJson(),
    );
  }

  String? _encodeUrl() {
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('attachment_enter_url'.tr());
      return null;
    }
    final String title = _urlTitleController.text.trim();
    final String label = title.isEmpty ? (_domainFromUrl(url) ?? url) : title;
    return TaskAttachmentCodec.encodeMap(
      UrlAttachmentPayload(
        url: url,
        label: label,
      ).toJson(),
    );
  }

  String? _urlAttachmentLabel() {
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      return null;
    }
    final String title = _urlTitleController.text.trim();
    return title.isEmpty ? (_domainFromUrl(url) ?? url) : title;
  }

  String? _encodeLocation() {
    final double? lat = _latitude;
    final double? lng = _longitude;
    if (lat == null || lng == null) {
      _showError('attachment_select_map_point'.tr());
      return null;
    }
    final String customLabel = _locationLabelController.text.trim();
    return TaskAttachmentCodec.encodeMap(
      LocationAttachmentPayload(
        latitude: lat,
        longitude: lng,
        placeName: _pickedPlaceName?.trim().isEmpty == true
            ? null
            : _pickedPlaceName?.trim(),
        label: customLabel.isEmpty ? null : customLabel,
      ).toJson(),
    );
  }

  String? _locationAttachmentLabel() {
    final String customLabel = _locationLabelController.text.trim();
    if (customLabel.isNotEmpty) {
      return customLabel;
    }
    final String? place = _pickedPlaceName?.trim();
    if (place != null && place.isNotEmpty) {
      return place;
    }
    return null;
  }

  String? _encodeNote() {
    final String body = _noteBodyController.text.trim();
    if (body.isEmpty) {
      _showError('attachment_enter_note'.tr());
      return null;
    }
    final String title = _noteTitleController.text.trim();
    final String resolvedTitle = title.isEmpty
        ? (body.length > 25 ? '${body.substring(0, 25)}...' : body)
        : title;
    return TaskAttachmentCodec.encodeMap(
      NoteAttachmentPayload(
        title: resolvedTitle,
        body: body,
      ).toJson(),
    );
  }

  String? _noteAttachmentLabel() {
    final String body = _noteBodyController.text.trim();
    if (body.isEmpty) {
      return null;
    }
    final String title = _noteTitleController.text.trim();
    if (title.isNotEmpty) {
      return title;
    }
    return body.length > 25 ? '${body.substring(0, 25)}...' : body;
  }

  String? _encodeChecklist() {
    final List<ChecklistItemPayload> items = _checklistItemsForSave();
    if (items.isEmpty) {
      _showError('attachment_add_checklist_item'.tr());
      return null;
    }
    final String title = _checklistTitleController.text.trim();
    return TaskAttachmentCodec.encodeMap(
      ChecklistAttachmentPayload(
        title: title.isEmpty ? null : title,
        items: items,
      ).toJson(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.isEditing
                    ? 'attachment_edit_title'.tr()
                    : 'attachment_new'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_selectedType == null) ...<Widget>[
                if (!widget.isEditing) ...<Widget>[
                  _AttachmentTemplateQuickStrip(
                    templates: _templates,
                    saving: _saving,
                    onApply: _applyTemplate,
                    onLongPress: _showTemplateMenu,
                    onCreate: _openNewTemplateForm,
                    onManage: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TemplatesPage(
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                      await _loadTemplates();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                ..._typePicker(),
              ]
              else
                ..._formForType(),
              const SizedBox(height: 16),
              if (_selectedType != null)
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isEditing
                              ? 'task_save_changes'.tr()
                              : 'common_save'.tr(),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typePicker() {
    return <Widget>[
      _typeTile(
        'attachment_type_contact'.tr(),
        Icons.contact_phone_outlined,
        TaskAttachmentType.contact,
      ),
      _typeTile(
        'attachment_type_photo'.tr(),
        Icons.image_outlined,
        TaskAttachmentType.image,
      ),
      _typeTile(
        'attachment_type_file'.tr(),
        Icons.insert_drive_file_outlined,
        TaskAttachmentType.file,
      ),
      _typeTile('attachment_type_url'.tr(), Icons.link, TaskAttachmentType.url),
      _typeTile(
        'attachment_type_location'.tr(),
        Icons.place_outlined,
        TaskAttachmentType.location,
      ),
      _typeTile(
        'attachment_type_note'.tr(),
        Icons.sticky_note_2_outlined,
        TaskAttachmentType.note,
      ),
      _typeTile(
        'attachment_type_checklist'.tr(),
        Icons.checklist,
        TaskAttachmentType.checklist,
      ),
    ];
  }

  Widget _typeTile(String label, IconData icon, TaskAttachmentType type) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        setState(() => _selectedType = type);
        if (type == TaskAttachmentType.contact) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pickContactSystem();
          });
        } else if (type == TaskAttachmentType.file) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pickFile();
          });
        }
      },
    );
  }

  List<Widget> _formForType() {
    final TaskAttachmentType type = _selectedType!;

    return <Widget>[
      Row(
        children: <Widget>[
          if (!widget.isEditing)
            IconButton(
              onPressed: () => setState(() {
                _selectedType = null;
                _pickedContact = null;
              }),
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Text(
              _typeTitle(type),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...switch (type) {
        TaskAttachmentType.contact => _contactForm(),
        TaskAttachmentType.image => _imageForm(),
        TaskAttachmentType.file => _fileForm(),
        TaskAttachmentType.url => _urlForm(),
        TaskAttachmentType.location => _locationForm(),
        TaskAttachmentType.note => _noteForm(),
        TaskAttachmentType.checklist => _checklistForm(),
      },
    ];
  }

  String _typeTitle(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.contact => 'attachment_type_contact'.tr(),
      TaskAttachmentType.image => 'attachment_type_photo'.tr(),
      TaskAttachmentType.file => 'attachment_type_file'.tr(),
      TaskAttachmentType.url => 'attachment_type_url'.tr(),
      TaskAttachmentType.location => 'attachment_type_location'.tr(),
      TaskAttachmentType.note => 'attachment_type_note'.tr(),
      TaskAttachmentType.checklist => 'attachment_type_checklist'.tr(),
    };
  }

  List<Widget> _contactForm() {
    final ContactAttachmentPayload? contact = _pickedContact;
    if (_pickingContact && contact == null) {
      return const <Widget>[
        Center(child: CircularProgressIndicator()),
      ];
    }
    return <Widget>[
      if (contact == null)
        OutlinedButton.icon(
          onPressed: _pickContactSystem,
          icon: const Icon(Icons.contacts_outlined),
          label: Text('attachment_pick_contact'.tr()),
        ),
      if (contact != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          contact.displayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (contact.primaryPhone.isNotEmpty)
          Text(contact.primaryPhone),
        if (contact.emails.isNotEmpty) Text(contact.emails.first),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickContactSystem,
          child: Text('attachment_pick_other_contact'.tr()),
        ),
      ],
    ];
  }

  List<Widget> _fileForm() => <Widget>[
        if (_storedFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                const Icon(Icons.insert_drive_file_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _storedFile!.fileName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(
            _storedFile != null
                ? 'attachment_pick_other_file'.tr()
                : 'attachment_pick_file'.tr(),
          ),
        ),
      ];

  List<Widget> _imageForm() => <Widget>[
        if (_imageRelativePath != null) ...<Widget>[
          FutureBuilder<File>(
            future: widget.fileStore.resolveFile(_imageRelativePath!),
            builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
              if (!snapshot.hasData || !snapshot.data!.existsSync()) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    snapshot.data!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            _imageRelativePath != null
                ? 'attachment_pick_other_photo'.tr()
                : 'attachment_pick_gallery'.tr(),
          ),
        ),
      ];

  List<Widget> _urlForm() => <Widget>[
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
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL',
            border: OutlineInputBorder(),
          ),
        ),
      ];

  List<Widget> _locationForm() => <Widget>[
        TextField(
          controller: _locationLabelController,
          decoration: InputDecoration(
            labelText: 'attachment_field_place_name'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickOnMap,
          icon: const Icon(Icons.map_outlined),
          label: Text('attachment_pick_on_map'.tr()),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _useCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: Text('attachment_current_location'.tr()),
        ),
      ];

  List<Widget> _noteForm() => <Widget>[
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
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'attachment_field_text'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
      ];

  List<Widget> _checklistForm() => <Widget>[
        ChecklistEditorSection(
          key: _checklistKey,
          titleController: _checklistTitleController,
          initialItems: _initialChecklistItems,
        ),
      ];
}

class _AttachmentTemplateQuickStrip extends StatelessWidget {
  const _AttachmentTemplateQuickStrip({
    required this.templates,
    required this.saving,
    required this.onApply,
    required this.onLongPress,
    required this.onCreate,
    required this.onManage,
  });

  final List<AttachmentTemplate> templates;
  final bool saving;
  final Future<void> Function(AttachmentTemplate template) onApply;
  final Future<void> Function(AttachmentTemplate template) onLongPress;
  final VoidCallback onCreate;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'attachment_templates_quick'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: onManage,
              child: Text('attachment_templates_manage'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              if (index == templates.length) {
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text('attachment_template_new'.tr()),
                  onPressed: saving ? null : onCreate,
                );
              }
              final AttachmentTemplate template = templates[index];
              return GestureDetector(
                onLongPress:
                    saving ? null : () => onLongPress(template),
                child: ActionChip(
                  avatar: Icon(
                    AttachmentTemplateLabels.iconFor(template.type),
                    size: 18,
                  ),
                  label: Text(
                    AttachmentTemplateLabels.displayTitle(template),
                  ),
                  onPressed: saving ? null : () => onApply(template),
                ),
              );
            },
          ),
        ),
        if (templates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'attachment_templates_chip_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'attachment_templates_empty_inline'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
