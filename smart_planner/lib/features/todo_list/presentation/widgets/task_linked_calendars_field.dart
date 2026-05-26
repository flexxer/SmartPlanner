import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_settings_page.dart';

/// Horizontal chips for calendars enabled in app settings.
class TaskLinkedCalendarsField extends StatefulWidget {
  const TaskLinkedCalendarsField({
    required this.selectedCalendarId,
    required this.onCalendarSelected,
    this.selectedCalendarIds,
    super.key,
  });

  final String? selectedCalendarId;
  final ValueChanged<DeviceCalendarInfo> onCalendarSelected;

  /// Optional override (e.g. dashboard day selection).
  final List<String>? selectedCalendarIds;

  @override
  State<TaskLinkedCalendarsField> createState() =>
      _TaskLinkedCalendarsFieldState();
}

class _TaskLinkedCalendarsFieldState extends State<TaskLinkedCalendarsField> {
  bool _loading = true;
  String? _errorMessage;
  bool _permissionDenied = false;
  bool _noneLinked = false;
  List<DeviceCalendarInfo> _calendars = <DeviceCalendarInfo>[];

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final LinkedCalendarsLoader loader = LinkedCalendarsLoader(
      calendarService: context.read<DeviceCalendarService>(),
      preferences: context.read<CalendarPreferencesRepository>(),
    );
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
      _errorMessage = result.errorMessage;
      _calendars = result.calendars;
    });

    if (_calendars.isNotEmpty &&
        (widget.selectedCalendarId == null ||
            widget.selectedCalendarId!.isEmpty)) {
      widget.onCalendarSelected(_calendars.first);
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (_permissionDenied) {
      return _MessageBanner(
        message: 'linked_calendars_permission'.tr(),
        actionLabel: 'linked_calendars_settings'.tr(),
        onAction: _openCalendarSettings,
      );
    }

    if (_errorMessage != null) {
      return _MessageBanner(
        message: _errorMessage!,
        actionLabel: 'common_retry'.tr(),
        onAction: _loadCalendars,
      );
    }

    if (_noneLinked || _calendars.isEmpty) {
      return _MessageBanner(
        message: 'linked_calendars_empty'.tr(),
        actionLabel: 'common_calendars'.tr(),
        onAction: _openCalendarSettings,
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
                    label: Text(calendar.name),
                    avatar: CircleAvatar(
                      radius: 8,
                      backgroundColor:
                          Color(_colorArgb(calendar.colorValue)),
                    ),
                    selected: calendar.id == widget.selectedCalendarId,
                    onSelected: (_) => widget.onCalendarSelected(calendar),
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

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}
