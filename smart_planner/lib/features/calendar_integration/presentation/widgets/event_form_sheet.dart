import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/presentation/widgets/confirm_delete_record.dart';
import 'package:smart_planner/core/presentation/widgets/form_sheet_scaffold.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_recurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/calendar_event_delete_dialog.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/linked_calendars_field.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_event_write_service.dart';
import 'package:smart_planner/features/calendar_integration/data/linked_calendars_loader.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/record_delete_coordinator.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_picker_field.dart';

/// Bottom sheet to create or edit a [CalendarEvent] (device calendar + Isar metadata).
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
  late DateTime _allDayEndDay;
  bool _isAllDay = false;
  String? _selectedCalendarId;
  DeviceCalendarInfo? _selectedCalendar;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.none;
  int? _reminderMinutes;
  bool _reminderLoaded = false;
  bool _saving = false;

  LinkedCalendarsLoader get _loader =>
      widget.linkedCalendarsLoader ?? LinkedCalendarsLoader();

  @override
  void initState() {
    super.initState();
    final CalendarEvent? existing = widget.eventToEdit;
    if (existing != null) {
      _titleController = TextEditingController(text: existing.title);
      _isAllDay = CalendarEventTimeUtils.isAllDay(existing);
      _start = existing.start;
      _end = existing.end;
      if (_isAllDay) {
        _allDayEndDay = AppDateUtils.startOfDay(
          existing.end.subtract(const Duration(minutes: 1)),
        );
      } else {
        _allDayEndDay = AppDateUtils.startOfDay(_end);
      }
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
      _allDayEndDay = day;
    }
    if (existing == null) {
      _loadDefaultReminder();
    }
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
    await context.read<ReminderSyncService>().syncEvent(event);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.startOfDay(_start),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (_isAllDay) {
        _start = AppDateUtils.startOfDay(picked);
        if (_allDayEndDay.isBefore(_start)) {
          _allDayEndDay = _start;
        }
        return;
      }

      final Duration span = _end.difference(_start);
      _start = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _start.hour,
        _start.minute,
      );
      _end = _start.add(span);
      if (!CalendarEventTimeUtils.isValidTimedRange(_start, _end)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickAllDayEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _allDayEndDay,
      firstDate: AppDateUtils.startOfDay(_start),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _allDayEndDay = AppDateUtils.startOfDay(picked));
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.startOfDay(_end),
      firstDate: AppDateUtils.startOfDay(_start),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _end = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _end.hour,
        _end.minute,
      );
      if (!CalendarEventTimeUtils.isValidTimedRange(_start, _end)) {
        _end = _start.add(const Duration(hours: 1));
      }
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
      if (!CalendarEventTimeUtils.isValidTimedRange(_start, _end)) {
        _end = DateTime(
          _start.year,
          _start.month,
          _start.day,
          time.hour,
          time.minute,
        ).add(const Duration(hours: 1));
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
      DateTime candidate = DateTime(
        _end.year,
        _end.month,
        _end.day,
        time.hour,
        time.minute,
      );
      if (!candidate.isAfter(_start)) {
        candidate = DateTime(
          _start.year,
          _start.month,
          _start.day,
          time.hour,
          time.minute,
        ).add(const Duration(days: 1));
      }
      _end = candidate;
    });
  }

  ({DateTime start, DateTime end}) _resolvedRange() {
    if (_isAllDay) {
      return CalendarEventTimeUtils.normalizeAllDayRange(
        startDay: _start,
        endDayInclusive: _allDayEndDay,
      );
    }
    return (start: _start, end: _end);
  }

  bool get _endOnDifferentDay =>
      !_isAllDay &&
      !AppDateUtils.isSameCalendarDay(_start, _end);

  RecurrenceRule? _buildRecurrenceRule() {
    if (_recurrenceFrequency == RecurrenceFrequency.none) {
      return null;
    }
    return RecurrenceRule(frequency: _recurrenceFrequency);
  }

  Future<void> _deleteEvent() async {
    final CalendarEvent? event = widget.eventToEdit;
    final DashboardBloc? bloc = widget.dashboardBloc;
    if (event == null || bloc == null) {
      return;
    }

    final bool confirmed = await confirmDeleteRecord(context);
    if (!confirmed || !mounted) {
      return;
    }

    await RecordDeleteCoordinator.deleteCalendarEvent(
      context,
      event: event,
      bloc: bloc,
      onDeleted: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
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
    if (_isAllDay) {
      if (_allDayEndDay.isBefore(AppDateUtils.startOfDay(_start))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('event_end_after_start'.tr())),
        );
        return;
      }
    } else if (!CalendarEventTimeUtils.isValidTimedRange(_start, _end)) {
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
    } on CalendarPermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('calendar_settings_permission_needed'.tr())),
        );
        setState(() => _saving = false);
      }
    } on CalendarServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() => _saving = false);
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
    final ({DateTime start, DateTime end}) range = _resolvedRange();
    final CalendarEventWriteService writer =
        context.read<CalendarEventWriteService>();
    final CalendarEvent event = await writer.save(
      title: title,
      start: range.start,
      end: range.end,
      calendar: calendar,
      recurrence: _buildRecurrenceRule(),
      reminderMinutesBefore: _reminderMinutes,
      allDay: _isAllDay,
    );
    await _syncReminderForEvent(event);
    _showReadOnlyNoticeIfNeeded(calendar);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveEdit({
    required String title,
    required DeviceCalendarInfo calendar,
  }) async {
    final ({DateTime start, DateTime end}) range = _resolvedRange();
    final CalendarEventWriteService writer =
        context.read<CalendarEventWriteService>();
    final CalendarEvent event = await writer.save(
      title: title,
      start: range.start,
      end: range.end,
      calendar: calendar,
      recurrence: _buildRecurrenceRule(),
      reminderMinutesBefore: _reminderMinutes,
      existing: widget.eventToEdit,
      allDay: _isAllDay,
    );
    await _syncReminderForEvent(event);
    _showReadOnlyNoticeIfNeeded(calendar);

    widget.dashboardBloc?.add(const LoadDashboardData());

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showReadOnlyNoticeIfNeeded(DeviceCalendarInfo calendar) {
    if (!calendar.isReadOnly || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('event_saved_read_only_calendar'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEditing = widget.isEditing;

    return FormSheetScaffold(
      title: isEditing ? 'event_edit'.tr() : 'event_new'.tr(),
      onDelete: isEditing ? _deleteEvent : null,
      deleteEnabled: !_saving,
      headerChildren: <Widget>[
        if (!isEditing) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'event_save_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ],
      children: <Widget>[
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'event_field_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              LinkedCalendarsField(
                style: LinkedCalendarsStyle.dropdown,
                linkedCalendarsLoader: _loader,
                selectedCalendarIds: widget.selectedCalendarIds,
                selectedCalendarId: _selectedCalendarId,
                isEditing: isEditing,
                permissionDeniedMessage: 'calendar_permission_request'.tr(),
                permissionDeniedActionLabel:
                    'calendar_settings_request_access'.tr(),
                emptyMessage: 'calendar_no_device_calendars'.tr(),
                errorRetryActionLabel: 'calendar_permission_retry'.tr(),
                onCalendarSelected: (DeviceCalendarInfo calendar) {
                  if (!isEditing && calendar.isReadOnly) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('calendar_read_only_cannot_select'.tr()),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _selectedCalendarId = calendar.id;
                    _selectedCalendar = calendar;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('event_field_all_day'.tr()),
                value: _isAllDay,
                onChanged: (bool value) {
                  setState(() {
                    _isAllDay = value;
                    if (value) {
                      _start = AppDateUtils.startOfDay(_start);
                      _allDayEndDay = AppDateUtils.startOfDay(_start);
                    }
                  });
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isAllDay
                      ? 'event_field_date'.tr()
                      : 'event_field_start'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickStartDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_start)),
              ),
              if (_isAllDay) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'event_field_end_date'.tr(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _pickAllDayEndDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(_formatDate(_allDayEndDay)),
                ),
              ] else ...<Widget>[
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
                if (_endOnDifferentDay) ...<Widget>[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      'event_end_date_label'.tr(
                        namedArgs: <String, String>{
                          'date': _formatDate(_end),
                        },
                      ),
                    ),
                  ),
                ],
              ],
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
              FormSheetSaveButton(
                label: isEditing
                    ? 'task_save_changes'.tr()
                    : 'common_save'.tr(),
                enabled: !_saving && _selectedCalendarId != null,
                onPressed: _save,
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
