import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_settings_page.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/device_calendar_picker_field.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_picker_field.dart';

/// Bottom sheet to create or edit a local [CalendarEvent] in Isar.
class EventFormSheet extends StatefulWidget {
  const EventFormSheet({
    required this.repository,
    this.eventToEdit,
    this.initialDay,
    this.initialStart,
    this.initialEnd,
    this.selectedCalendarIds = const <String>[],
    this.dashboardBloc,
    this.linkedCalendarsLoader,
    this.initialTitle,
    super.key,
  });

  final LocalCalendarEventRepository repository;

  /// When set, the sheet opens in edit mode with fields prefilled.
  final CalendarEvent? eventToEdit;

  /// Day anchor for new events (required when [eventToEdit] is null).
  final DateTime? initialDay;

  /// Optional prefilled start/end when creating from the time grid.
  final DateTime? initialStart;
  final DateTime? initialEnd;

  final List<String> selectedCalendarIds;
  final DashboardBloc? dashboardBloc;
  final LinkedCalendarsLoader? linkedCalendarsLoader;

  /// Prefilled title when creating (e.g. from a deep link).
  final String? initialTitle;

  bool get isEditing => eventToEdit != null;

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  late final TextEditingController _titleController;
  late DateTime _start;
  late DateTime _end;
  String? _selectedCalendarId;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.none;
  int? _reminderMinutes;
  bool _reminderLoaded = false;
  bool _saving = false;
  bool _loadingCalendars = true;
  String? _calendarLoadError;
  bool _permissionDenied = false;
  bool _noneLinked = false;
  bool _showingAllDeviceCalendars = false;
  List<DeviceCalendarInfo> _linkedCalendars = <DeviceCalendarInfo>[];

  LinkedCalendarsLoader get _loader =>
      widget.linkedCalendarsLoader ?? LinkedCalendarsLoader();

  @override
  void initState() {
    super.initState();
    final CalendarEvent? existing = widget.eventToEdit;
    if (existing != null) {
      _titleController = TextEditingController(text: existing.title);
      _start = existing.start;
      _end = existing.end;
      _selectedCalendarId = existing.calendarId;
      _recurrenceFrequency =
          existing.recurrenceRule?.frequency ?? RecurrenceFrequency.none;
      _reminderMinutes = existing.reminderMinutesBefore;
      _reminderLoaded = true;
    } else {
      _titleController = TextEditingController(
        text: widget.initialTitle ?? '',
      );
      final DateTime day =
          AppDateUtils.startOfDay(widget.initialDay ?? DateTime.now());
      if (widget.initialStart != null && widget.initialEnd != null) {
        _start = widget.initialStart!;
        _end = widget.initialEnd!;
      } else {
        _start = day.add(const Duration(hours: 10));
        _end = day.add(const Duration(hours: 11));
      }
    }
    if (existing == null) {
      _loadDefaultReminder();
    }
    _loadLinkedCalendars();
  }

  Future<void> _loadDefaultReminder() async {
    final NotificationPreferencesRepository prefs =
        NotificationPreferencesRepository();
    final int minutes = await prefs.getDefaultReminderMinutes();
    if (mounted) {
      setState(() {
        _reminderMinutes = minutes;
        _reminderLoaded = true;
      });
    }
  }

  Future<void> _syncReminderForEvent(CalendarEvent event) async {
    try {
      await ItemReminderScheduler().syncEvent(event);
    } on Object {
      // Best-effort after save.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedCalendars() async {
    setState(() {
      _loadingCalendars = true;
      _calendarLoadError = null;
      _permissionDenied = false;
      _noneLinked = false;
      _showingAllDeviceCalendars = false;
    });

    final LinkedCalendarsLoadResult result = await _loader.load(
      selectedCalendarIds: widget.selectedCalendarIds,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingCalendars = false;
      _permissionDenied = result.permissionDenied;
      _noneLinked = result.noneLinked;
      _showingAllDeviceCalendars = result.showingAllDeviceCalendars;
      _calendarLoadError = result.errorMessage;
      _linkedCalendars = result.calendars;
      if (_selectedCalendarId == null && result.calendars.isNotEmpty) {
        _selectedCalendarId = result.calendars.first.id;
      }
    });
  }

  Future<void> _openCalendarSettings() async {
    final DashboardBloc? dashboardBloc = widget.dashboardBloc;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext routeContext) {
          final Widget page = const CalendarSettingsPage();
          if (dashboardBloc == null) {
            return page;
          }
          return BlocProvider<DashboardBloc>.value(
            value: dashboardBloc,
            child: page,
          );
        },
      ),
    );
    if (mounted) {
      await _loadLinkedCalendars();
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.startOfDay(_start),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    final Duration span = _end.difference(_start);
    final DateTime newStart = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _start.hour,
      _start.minute,
    );
    final DateTime newEnd = newStart.add(span);
    setState(() {
      _start = newStart;
      _end = newEnd.isAfter(_start) ? newEnd : _start.add(const Duration(hours: 1));
    });
  }

  Future<void> _pickStart() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        time.hour,
        time.minute,
      );
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _end = DateTime(
        _end.year,
        _end.month,
        _end.day,
        time.hour,
        time.minute,
      );
    });
  }

  DeviceCalendarInfo? get _selectedCalendar {
    final String? id = _selectedCalendarId;
    if (id == null) {
      return null;
    }
    for (final DeviceCalendarInfo calendar in _linkedCalendars) {
      if (calendar.id == id) {
        return calendar;
      }
    }
    return null;
  }

  RecurrenceRule? _buildRecurrenceRule() {
    if (_recurrenceFrequency == RecurrenceFrequency.none) {
      return null;
    }
    return RecurrenceRule(frequency: _recurrenceFrequency);
  }

  Future<bool> _confirmDeleteRecord() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme dialogColors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text('delete_dialog_title'.tr()),
          content: Text('delete_dialog_body'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('common_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: dialogColors.error,
                foregroundColor: dialogColors.onError,
              ),
              child: Text('common_delete'.tr()),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _deleteEvent() async {
    final CalendarEvent? event = widget.eventToEdit;
    final DashboardBloc? bloc = widget.dashboardBloc;
    if (event == null || bloc == null) {
      return;
    }

    final bool confirmed = await _confirmDeleteRecord();
    if (!confirmed || !mounted) {
      return;
    }

    bloc.add(DeleteCalendarEvent(event.id));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final DeviceCalendarInfo? calendar = _selectedCalendar;
    if (calendar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('task_select_calendar'.tr())),
      );
      return;
    }

    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('event_enter_title'.tr())),
      );
      return;
    }
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('event_end_after_start'.tr())),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.isEditing) {
        await _saveEdit(title: title, calendar: calendar);
      } else {
        await _saveCreate(title: title, calendar: calendar);
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'common_error_with_details'.tr(
                namedArgs: <String, String>{'details': '$e'},
              ),
            ),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveCreate({
    required String title,
    required DeviceCalendarInfo calendar,
  }) async {
    final CalendarEvent event = CalendarEvent.createLocal(
      title: title,
      start: _start,
      end: _end,
      calendarId: calendar.id,
      colorValue: calendar.colorValue,
      recurrenceRule: _buildRecurrenceRule(),
    )..reminderMinutesBefore = _reminderMinutes;
    await widget.repository.saveLocalEvent(event);
    await _syncReminderForEvent(event);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveEdit({
    required String title,
    required DeviceCalendarInfo calendar,
  }) async {
    final CalendarEvent event = widget.eventToEdit!
      ..title = title
      ..start = _start
      ..end = _end
      ..calendarId = calendar.id
      ..colorValue = calendar.colorValue
      ..recurrenceRule = _buildRecurrenceRule()
      ..reminderMinutesBefore = _reminderMinutes;

    await widget.repository.saveLocalEvent(event);
    await _syncReminderForEvent(event);

    widget.dashboardBloc?.add(const LoadDashboardData());

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEditing = widget.isEditing;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      isEditing ? 'event_edit'.tr() : 'event_new'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      tooltip: 'event_delete_tooltip'.tr(),
                      onPressed: _saving ? null : _deleteEvent,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colors.error,
                      ),
                    ),
                ],
              ),
              if (!isEditing) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'event_save_hint'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'event_field_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              _buildCalendarPicker(context, colors),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'event_field_date'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_start)),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.access_time),
                      label: Text(_formatTime(_start)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.access_time_filled),
                      label: Text(_formatTime(_end)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: _recurrenceFrequency,
                decoration: InputDecoration(
                  labelText: 'event_field_recurrence'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: RecurrenceFrequency.values
                    .map(
                      (RecurrenceFrequency frequency) =>
                          DropdownMenuItem<RecurrenceFrequency>(
                        value: frequency,
                        child: Text(_recurrenceLabel(frequency)),
                      ),
                    )
                    .toList(),
                onChanged: (RecurrenceFrequency? value) {
                  if (value != null) {
                    setState(() => _recurrenceFrequency = value);
                  }
                },
              ),
              if (_reminderLoaded) ...<Widget>[
                const SizedBox(height: 12),
                ReminderPickerField(
                  valueMinutes: _reminderMinutes,
                  onChanged: (int? minutes) {
                    setState(() => _reminderMinutes = minutes);
                  },
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditing
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

  bool get _canSave =>
      !_saving && !_loadingCalendars && _selectedCalendarId != null;

  Widget _buildCalendarPicker(BuildContext context, ColorScheme colors) {
    if (_loadingCalendars) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_permissionDenied) {
      return _CalendarPickerMessage(
        message: 'calendar_permission_request'.tr(),
        actionLabel: 'calendar_settings_request_access'.tr(),
        onAction: _loadLinkedCalendars,
      );
    }

    if (_calendarLoadError != null) {
      return _CalendarPickerMessage(
        message: _calendarLoadError!,
        actionLabel: 'calendar_permission_retry'.tr(),
        onAction: _loadLinkedCalendars,
      );
    }

    if (_noneLinked || _linkedCalendars.isEmpty) {
      return _CalendarPickerMessage(
        message:
            'calendar_no_device_calendars'.tr(),
        actionLabel: 'common_calendars'.tr(),
        onAction: _openCalendarSettings,
      );
    }

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
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        DeviceCalendarPickerField(
          calendars: _linkedCalendars,
          selectedCalendarId: _selectedCalendarId,
          onCalendarSelected: (DeviceCalendarInfo calendar) {
            setState(() => _selectedCalendarId = calendar.id);
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return L10n.dateFormat('d MMMM y', context: context).format(date);
  }

  static String _formatTime(DateTime date) {
    final String h = date.hour.toString().padLeft(2, '0');
    final String m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _recurrenceLabel(RecurrenceFrequency frequency) {
    return L10n.recurrenceLabel(frequency.name);
  }
}

class _CalendarPickerMessage extends StatelessWidget {
  const _CalendarPickerMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
