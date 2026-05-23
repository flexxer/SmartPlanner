import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/services/device_contact_picker.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/data/services/osm_place_search_service.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/location_map_picker_sheet.dart';

/// Add a local [TaskAttachment] to a task.
class AddAttachmentSheet extends StatefulWidget {
  const AddAttachmentSheet({
    required this.repository,
    required this.taskId,
    super.key,
  });

  final TaskAttachmentRepository repository;
  final Id taskId;

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
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteBodyController = TextEditingController();
  final TextEditingController _checklistTitleController = TextEditingController();
  final TextEditingController _checklistItemController = TextEditingController();
  final List<ChecklistItemPayload> _checklistItems = <ChecklistItemPayload>[];

  String? _imageRelativePath;

  /// Nominatim [display_name] from the last map pick or reverse geocode.
  String? _pickedPlaceName;

  @override
  void dispose() {
    _urlTitleController.dispose();
    _urlController.dispose();
    _locationLabelController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _noteTitleController.dispose();
    _noteBodyController.dispose();
    _checklistTitleController.dispose();
    _checklistItemController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final String? path = await widget.repository.fileStore.pickAndStoreImage();
    if (path != null && mounted) {
      setState(() => _imageRelativePath = path);
    }
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
          _showError('Не удалось открыть контакты');
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка: $e');
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
      _showError('Службы геолокации выключены');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError('Нет разрешения на геолокацию');
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
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
      _pickedPlaceName = placeName;
      if (placeName != null &&
          placeName.isNotEmpty &&
          _locationLabelController.text.trim().isEmpty) {
        _locationLabelController.text = placeName;
      }
    });
  }

  Future<void> _pickOnMap() async {
    final double? lat = double.tryParse(_latController.text.trim());
    final double? lng = double.tryParse(_lngController.text.trim());
    final LocationPickResult? result = await showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LocationMapPickerSheet(
        initialLatitude: lat,
        initialLongitude: lng,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
        _pickedPlaceName = result.placeName;
        if (_locationLabelController.text.trim().isEmpty &&
            result.placeName != null &&
            result.placeName!.trim().isNotEmpty) {
          _locationLabelController.text = result.placeName!.trim();
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _commitChecklistLine(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _checklistItems.add(
        ChecklistItemPayload(
          localId: TaskAttachmentChecklist.nextItemLocalId(_checklistItems),
          text: trimmed,
        ),
      );
      _checklistItemController.clear();
    });
  }

  List<ChecklistItemPayload> _checklistItemsForSave() {
    final List<ChecklistItemPayload> items =
        List<ChecklistItemPayload>.from(_checklistItems);
    final String pending = _checklistItemController.text.trim();
    if (pending.isNotEmpty) {
      items.add(
        ChecklistItemPayload(
          localId: TaskAttachmentChecklist.nextItemLocalId(items),
          text: pending,
        ),
      );
    }
    return items;
  }

  Future<void> _save() async {
    final TaskAttachmentType? type = _selectedType;
    if (type == null) {
      _showError('Выберите тип вложения');
      return;
    }

    final String? payloadJson = switch (type) {
      TaskAttachmentType.contact => _encodeContact(),
      TaskAttachmentType.image => _encodeImage(),
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
      final int sortOrder = await widget.repository.nextSortOrder(widget.taskId);
      final String? attachmentLabel = type == TaskAttachmentType.location
          ? _locationAttachmentLabel()
          : null;
      await widget.repository.save(
        TaskAttachment.create(
          taskId: widget.taskId,
          type: type,
          payloadJson: payloadJson,
          label: attachmentLabel,
          sortOrder: sortOrder,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка: $e');
        setState(() => _saving = false);
      }
    }
  }

  String? _encodeContact() {
    final ContactAttachmentPayload? contact = _pickedContact;
    if (contact == null) {
      _showError('Выберите контакт');
      return null;
    }
    return TaskAttachmentCodec.encodeMap(contact.toJson());
  }

  String? _encodeImage() {
    if (_imageRelativePath == null) {
      _showError('Выберите изображение');
      return null;
    }
    return TaskAttachmentCodec.encodeMap(
      ImageAttachmentPayload(relativePath: _imageRelativePath!).toJson(),
    );
  }

  String? _encodeUrl() {
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Укажите URL');
      return null;
    }
    final String title = _urlTitleController.text.trim();
    return TaskAttachmentCodec.encodeMap(
      UrlAttachmentPayload(
        url: url,
        label: title.isEmpty ? null : title,
      ).toJson(),
    );
  }

  String? _encodeLocation() {
    final double? lat = double.tryParse(_latController.text.trim());
    final double? lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      _showError('Укажите координаты или выберите точку на карте');
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
      _showError('Введите текст заметки');
      return null;
    }
    final String title = _noteTitleController.text.trim();
    return TaskAttachmentCodec.encodeMap(
      NoteAttachmentPayload(
        title: title.isEmpty ? null : title,
        body: body,
      ).toJson(),
    );
  }

  String? _encodeChecklist() {
    final List<ChecklistItemPayload> items = _checklistItemsForSave();
    if (items.isEmpty) {
      _showError('Добавьте хотя бы один пункт');
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
                'Новое вложение',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_selectedType == null) ..._typePicker() else ..._formForType(),
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
                      : const Text('Сохранить'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _typePicker() {
    return <Widget>[
      _typeTile('Контакт', Icons.contact_phone_outlined, TaskAttachmentType.contact),
      _typeTile('Фото', Icons.image_outlined, TaskAttachmentType.image),
      _typeTile('Ссылка', Icons.link, TaskAttachmentType.url),
      _typeTile('Место', Icons.place_outlined, TaskAttachmentType.location),
      _typeTile('Заметка', Icons.sticky_note_2_outlined, TaskAttachmentType.note),
      _typeTile('Чеклист', Icons.checklist, TaskAttachmentType.checklist),
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
        }
      },
    );
  }

  List<Widget> _formForType() {
    final TaskAttachmentType type = _selectedType!;

    return <Widget>[
      Row(
        children: <Widget>[
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
        TaskAttachmentType.url => _urlForm(),
        TaskAttachmentType.location => _locationForm(),
        TaskAttachmentType.note => _noteForm(),
        TaskAttachmentType.checklist => _checklistForm(),
      },
    ];
  }

  String _typeTitle(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.contact => 'Контакт',
      TaskAttachmentType.image => 'Фото',
      TaskAttachmentType.url => 'Ссылка',
      TaskAttachmentType.location => 'Геопозиция',
      TaskAttachmentType.note => 'Заметка',
      TaskAttachmentType.checklist => 'Чеклист',
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
          label: const Text('Выбрать контакт'),
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
          child: const Text('Выбрать другой контакт'),
        ),
      ],
    ];
  }

  List<Widget> _imageForm() => <Widget>[
        if (_imageRelativePath != null) ...<Widget>[
          FutureBuilder<File>(
            future: widget.repository.fileStore.resolveFile(_imageRelativePath!),
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
                ? 'Выбрать другое фото'
                : 'Выбрать из галереи',
          ),
        ),
      ];

  List<Widget> _urlForm() => <Widget>[
        TextField(
          controller: _urlTitleController,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
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
          decoration: const InputDecoration(
            labelText: 'Название места (необязательно)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickOnMap,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Выбрать на карте'),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Широта',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Долгота',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _useCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: const Text('Текущее местоположение'),
        ),
      ];

  List<Widget> _noteForm() => <Widget>[
        TextField(
          controller: _noteTitleController,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteBodyController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Текст',
            border: OutlineInputBorder(),
          ),
        ),
      ];

  List<Widget> _checklistForm() => <Widget>[
        TextField(
          controller: _checklistTitleController,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ..._checklistItems.map(
          (ChecklistItemPayload item) => Text('• ${item.text}'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _checklistItemController,
                decoration: const InputDecoration(
                  hintText: 'Пункт чеклиста',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _commitChecklistLine,
              ),
            ),
            IconButton(
              onPressed: () => _commitChecklistLine(_checklistItemController.text),
              icon: const Icon(Icons.add),
              tooltip: 'Добавить пункт',
            ),
          ],
        ),
      ];
}
