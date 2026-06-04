import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/presentation/widgets/calendar_picker_message.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_settings_page.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/device_calendar_picker_field.dart';

enum LinkedCalendarsStyle {
  chips,
  dropdown,
}

/// Loads enabled device calendars and shows chips or a dropdown picker.
class LinkedCalendarsField extends StatefulWidget {
  const LinkedCalendarsField({
    required this.selectedCalendarId,
    required this.onCalendarSelected,
    this.selectedCalendarIds,
    this.style = LinkedCalendarsStyle.chips,
    this.linkedCalendarsLoader,
    this.isEditing = false,
    this.permissionDeniedMessage,
    this.permissionDeniedActionLabel,
    this.emptyMessage,
    this.emptyActionLabel,
    this.errorRetryActionLabel,
    super.key,
  });

  final String? selectedCalendarId;
  final ValueChanged<DeviceCalendarInfo> onCalendarSelected;
  final List<String>? selectedCalendarIds;
  final LinkedCalendarsStyle style;
  final LinkedCalendarsLoader? linkedCalendarsLoader;
  final bool isEditing;

  final String? permissionDeniedMessage;
  final String? permissionDeniedActionLabel;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final String? errorRetryActionLabel;

  @override
  State<LinkedCalendarsField> createState() => _LinkedCalendarsFieldState();
}

class _LinkedCalendarsFieldState extends State<LinkedCalendarsField> {
  bool _loading = true;
  String? _errorMessage;
  bool _permissionDenied = false;
  bool _noneLinked = false;
  bool _showingAllDeviceCalendars = false;
  List<DeviceCalendarInfo> _calendars = <DeviceCalendarInfo>[];

  LinkedCalendarsLoader get _loader =>
      widget.linkedCalendarsLoader ?? LinkedCalendarsLoader();

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
      _showingAllDeviceCalendars = false;
    });

    final LinkedCalendarsLoader loader = widget.style == LinkedCalendarsStyle.chips
        ? LinkedCalendarsLoader(
            calendarService: context.read<DeviceCalendarService>(),
            preferences: context.read<CalendarPreferencesRepository>(),
          )
        : _loader;

    final LinkedCalendarsLoadResult result = await loader.load(
      selectedCalendarIds: widget.selectedCalendarIds,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _permissionDenied = result.permissionDenied;
      _noneLinked = result.noneLinked;
      _showingAllDeviceCalendars = result.showingAllDeviceCalendars;
      _errorMessage = result.errorMessage;
      _calendars = result.calendars;
    });

    if (_calendars.isNotEmpty) {
      final String? currentId = widget.selectedCalendarId;
      if (currentId == null || currentId.isEmpty) {
        widget.onCalendarSelected(_calendars.first);
      } else {
        for (final DeviceCalendarInfo calendar in _calendars) {
          if (calendar.id == currentId) {
            widget.onCalendarSelected(calendar);
            break;
          }
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      if (widget.style == LinkedCalendarsStyle.chips) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(),
        );
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_permissionDenied) {
      return CalendarPickerMessage(
        message: widget.permissionDeniedMessage ??
            'linked_calendars_permission'.tr(),
        actionLabel: widget.permissionDeniedActionLabel ??
            'linked_calendars_settings'.tr(),
        onAction: widget.style == LinkedCalendarsStyle.chips
            ? _openCalendarSettings
            : _loadCalendars,
        compact: widget.style == LinkedCalendarsStyle.chips,
      );
    }

    if (_errorMessage != null) {
      return CalendarPickerMessage(
        message: _errorMessage!,
        actionLabel:
            widget.errorRetryActionLabel ?? 'common_retry'.tr(),
        onAction: _loadCalendars,
        compact: widget.style == LinkedCalendarsStyle.chips,
      );
    }

    if (_noneLinked || _calendars.isEmpty) {
      return CalendarPickerMessage(
        message: widget.emptyMessage ?? 'linked_calendars_empty'.tr(),
        actionLabel: widget.emptyActionLabel ?? 'common_calendars'.tr(),
        onAction: _openCalendarSettings,
        compact: widget.style == LinkedCalendarsStyle.chips,
      );
    }

    if (widget.style == LinkedCalendarsStyle.dropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_showingAllDeviceCalendars)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.isEditing
                    ? 'calendar_saved_selection_missing'.tr()
                    : 'calendar_saved_selection_missing_settings'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          DeviceCalendarPickerField(
            calendars: _calendars,
            selectedCalendarId: widget.selectedCalendarId,
            writableOnly: !widget.isEditing,
            onCalendarSelected: widget.onCalendarSelected,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'common_calendar'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final DeviceCalendarInfo calendar in _calendars)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      calendar.isReadOnly
                          ? '${calendar.name} (${'calendar_read_only_badge'.tr()})'
                          : calendar.name,
                    ),
                    avatar: CircleAvatar(
                      radius: 8,
                      backgroundColor:
                          Color(_colorArgb(calendar.colorValue)),
                    ),
                    selected: calendar.id == widget.selectedCalendarId,
                    onSelected: calendar.isReadOnly
                        ? null
                        : (_) => widget.onCalendarSelected(calendar),
                  ),
                ),
            ],
          ),
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
