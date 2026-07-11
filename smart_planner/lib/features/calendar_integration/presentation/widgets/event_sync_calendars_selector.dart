import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/presentation/widgets/calendar_picker_message.dart';
import 'package:smart_planner/core/presentation/widgets/form_sheet_scaffold.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_settings_page.dart';

/// Multi-select picker for writable calendars enabled in app settings.
///
/// Used when creating an event (inline) and when syncing from event detail.
class EventSyncCalendarsSelector extends StatefulWidget {
  const EventSyncCalendarsSelector({
    required this.selectedCalendarIds,
    required this.onSelectionChanged,
    this.linkedCalendarsLoader,
    this.compact = false,
    super.key,
  });

  final Set<String> selectedCalendarIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final LinkedCalendarsLoader? linkedCalendarsLoader;
  final bool compact;

  @override
  State<EventSyncCalendarsSelector> createState() =>
      _EventSyncCalendarsSelectorState();
}

class _EventSyncCalendarsSelectorState extends State<EventSyncCalendarsSelector> {
  bool _loading = true;
  String? _errorMessage;
  bool _permissionDenied = false;
  bool _noneLinked = false;
  List<DeviceCalendarInfo> _calendars = <DeviceCalendarInfo>[];

  LinkedCalendarsLoader get _loader =>
      widget.linkedCalendarsLoader ??
      LinkedCalendarsLoader(
        calendarService: context.read<DeviceCalendarService>(),
        preferences: context.read<CalendarPreferencesRepository>(),
      );

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _permissionDenied = false;
      _noneLinked = false;
    });

    final LinkedCalendarsLoadResult result = await _loader.load();

    if (!mounted) {
      return;
    }

    final List<DeviceCalendarInfo> writable = result.calendars
        .where((DeviceCalendarInfo c) => !c.isReadOnly)
        .toList(growable: false);

    setState(() {
      _loading = false;
      _permissionDenied = result.permissionDenied;
      _noneLinked = result.noneLinked || writable.isEmpty;
      _errorMessage = result.errorMessage;
      _calendars = writable;
    });
  }

  Future<void> _openCalendarSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CalendarSettingsPage(),
      ),
    );
    if (mounted) {
      await _loadCalendars();
    }
  }

  void _toggleCalendar(DeviceCalendarInfo calendar, bool selected) {
    final Set<String> next = Set<String>.from(widget.selectedCalendarIds);
    if (selected) {
      next.add(calendar.id);
    } else {
      next.remove(calendar.id);
    }
    widget.onSelectionChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: widget.compact ? 8 : 12),
        child: widget.compact
            ? const LinearProgressIndicator()
            : const Center(child: CircularProgressIndicator()),
      );
    }

    if (_permissionDenied) {
      return CalendarPickerMessage(
        message: 'event_sync_permission'.tr(),
        actionLabel: 'calendar_settings_request_access'.tr(),
        onAction: _loadCalendars,
        compact: widget.compact,
      );
    }

    if (_errorMessage != null) {
      return CalendarPickerMessage(
        message: _errorMessage!,
        actionLabel: 'common_retry'.tr(),
        onAction: _loadCalendars,
        compact: widget.compact,
      );
    }

    if (_noneLinked) {
      return CalendarPickerMessage(
        message: 'event_sync_no_calendars'.tr(),
        actionLabel: 'common_calendars'.tr(),
        onAction: _openCalendarSettings,
        compact: widget.compact,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'event_sync_calendars_label'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'event_sync_calendars_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        for (final DeviceCalendarInfo calendar in _calendars)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: widget.selectedCalendarIds.contains(calendar.id),
            onChanged: (bool? value) {
              if (value == null) {
                return;
              }
              _toggleCalendar(calendar, value);
            },
            secondary: CircleAvatar(
              radius: 8,
              backgroundColor: Color(_colorArgb(calendar.colorValue)),
            ),
            title: Text(calendar.name),
            subtitle: (calendar.accountName ?? '').trim().isEmpty
                ? null
                : Text(calendar.accountName!),
          ),
      ],
    );
  }

  static int _colorArgb(int value) {
    if (value > 0xFFFFFF) {
      return value;
    }
    return 0xFF000000 | value;
  }
}

/// Bottom sheet to pick calendars and confirm outbound sync.
class EventSyncCalendarsSheet {
  EventSyncCalendarsSheet._();

  static Future<Set<String>?> show(
    BuildContext context, {
    Set<String> initialSelected = const <String>{},
    LinkedCalendarsLoader? linkedCalendarsLoader,
  }) async {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final Set<String> selected = Set<String>.from(initialSelected);
        var saving = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return FormSheetScaffold(
              title: 'event_sync_title'.tr(),
              children: <Widget>[
                EventSyncCalendarsSelector(
                  linkedCalendarsLoader: linkedCalendarsLoader,
                  selectedCalendarIds: selected,
                  onSelectionChanged: (Set<String> ids) {
                    setSheetState(() => selected
                      ..clear()
                      ..addAll(ids));
                  },
                ),
                const SizedBox(height: 16),
                FormSheetSaveButton(
                  label: 'event_sync_action'.tr(),
                  enabled: !saving && selected.isNotEmpty,
                  onPressed: () {
                    if (selected.isEmpty) {
                      return;
                    }
                    Navigator.of(sheetContext).pop(Set<String>.from(selected));
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
