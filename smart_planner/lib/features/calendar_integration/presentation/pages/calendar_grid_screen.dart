import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/linked_calendar_ids_resolver.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';
import 'package:smart_planner/features/notifications/data/reminder_sync_service.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/calendar_grid_month_view.dart';
import 'package:smart_planner/features/calendar_integration/presentation/widgets/calendar_grid_week_view.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_day_markers_repository.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/dashboard/presentation/dashboard_screen.dart';

/// Day / multi-day / week / month time grid for calendar events.
class CalendarGridScreen extends StatefulWidget {
  const CalendarGridScreen({super.key});

  @override
  State<CalendarGridScreen> createState() => _CalendarGridScreenState();
}

enum _CalendarGridMode { day, threeDays, week, month }

class _CalendarGridScreenState extends State<CalendarGridScreen> {
  _CalendarGridMode _mode = _CalendarGridMode.week;
  late DateTime _rangeStart;
  late DateTime _focusedMonth;
  List<CalendarEvent> _storedEvents = <CalendarEvent>[];
  Map<int, DayActivityMarker> _dayMarkers = <int, DayActivityMarker>{};
  bool _loading = true;
  String? _loadError;

  int get _timeViewDayCount => switch (_mode) {
        _CalendarGridMode.day => 1,
        _CalendarGridMode.threeDays => 3,
        _CalendarGridMode.week => 7,
        _CalendarGridMode.month => 0,
      };

  @override
  void initState() {
    super.initState();
    final DashboardState state = context.read<DashboardBloc>().state;
    final DateTime anchor = state is DashboardLoaded
        ? state.selectedDate
        : DateTime.now();
    _rangeStart = AppDateUtils.startOfWeek(anchor);
    _focusedMonth = DateTime(anchor.year, anchor.month, 1);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final ({DateTime start, DateTime end}) range = _markerRange();
    final CalendarService calendarService = context.read<CalendarService>();
    final CalendarPreferencesRepository calendarPreferences =
        context.read<CalendarPreferencesRepository>();
    final LocalCalendarEventRepository localRepo =
        context.read<LocalCalendarEventRepository>();
    final DashboardDayMarkersRepository markersRepo =
        context.read<DashboardDayMarkersRepository>();

    final List<String> calendarIds =
        await LinkedCalendarIdsResolver.resolveForDeviceSync(
      calendarService: calendarService,
      preferences: calendarPreferences,
    );

    List<CalendarEvent> deviceEvents = const <CalendarEvent>[];
    try {
      if (calendarIds.isNotEmpty) {
        deviceEvents = await calendarService.getEvents(
          calendarIds: calendarIds,
          from: range.start.subtract(const Duration(days: 1)),
          to: range.end.add(const Duration(days: 2)),
        );
        await localRepo.upsertDeviceEvents(deviceEvents);
        await localRepo.purgeStaleDeviceEvents(
          fetchedInWindow: deviceEvents,
          windowStart: AppDateUtils.startOfDay(range.start),
          windowEndExclusive: AppDateUtils.startOfDay(range.end)
              .add(const Duration(days: 1)),
          syncedCalendarIds: calendarIds.toSet(),
        );
        if (mounted) {
          await context.read<ReminderSyncService>().syncDeviceEventsAfterUpsert(
            localEvents: localRepo,
            fromDevice: deviceEvents,
          );
        }
      }
    } on CalendarPermissionDeniedException {
      if (mounted) {
        setState(() {
          _loadError = 'calendar_events_error_android_permission'.tr();
        });
      }
    } on CalendarServiceException catch (e) {
      if (mounted) {
        setState(() => _loadError = e.toString());
      }
    }

    final List<CalendarEvent> allStored = await localRepo.getAll();
    final List<CalendarEvent> stored = VisibleCalendarEventsMerger.mergeForRange(
      rangeStart: range.start,
      rangeEnd: range.end,
      deviceEventsInRange: deviceEvents,
      allStored: allStored,
    );
    final Map<int, DayActivityMarker> markers = await markersRepo.loadForRange(
      rangeStart: range.start,
      rangeEnd: range.end,
      calendarIds: calendarIds,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _storedEvents = stored;
      _dayMarkers = markers;
      _loading = false;
    });
  }

  ({DateTime start, DateTime end}) _markerRange() {
    switch (_mode) {
      case _CalendarGridMode.day:
        return (start: _rangeStart, end: _rangeStart);
      case _CalendarGridMode.threeDays:
        return (
          start: _rangeStart,
          end: _rangeStart.add(const Duration(days: 2)),
        );
      case _CalendarGridMode.week:
        return (
          start: _rangeStart,
          end: _rangeStart.add(const Duration(days: 6)),
        );
      case _CalendarGridMode.month:
        final DateTime monthStart =
            DateTime(_focusedMonth.year, _focusedMonth.month, 1);
        final DateTime monthEnd =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
        return (
          start: monthStart.subtract(const Duration(days: 7)),
          end: monthEnd.add(const Duration(days: 7)),
        );
    }
  }

  void _setMode(_CalendarGridMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      if (mode == _CalendarGridMode.week) {
        _rangeStart = AppDateUtils.startOfWeek(_rangeStart);
      } else if (mode == _CalendarGridMode.day ||
          mode == _CalendarGridMode.threeDays) {
        _rangeStart = AppDateUtils.startOfDay(DateTime.now());
      }
    });
    _loadData();
  }

  void _shiftRange(int deltaDays) {
    setState(() {
      _rangeStart = _rangeStart.add(Duration(days: deltaDays));
    });
    _loadData();
  }

  void _onMonthPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    });
    _loadData();
  }

  void _onMonthDaySelected(DateTime day) {
    setState(() {
      _rangeStart = AppDateUtils.startOfDay(day);
      _focusedMonth = DateTime(day.year, day.month, 1);
      _mode = _CalendarGridMode.day;
    });
    _loadData();
  }

  List<String> _selectedCalendarIds() {
    final DashboardState state = context.read<DashboardBloc>().state;
    return state is DashboardLoaded
        ? state.selectedCalendarIds
        : const <String>[];
  }

  Future<void> _openCreateFromSlot(
    DateTime day,
    DateTime start,
    DateTime end,
  ) async {
    await DashboardScreen.openEventFormSheet(
      context,
      initialDay: day,
      initialStart: start,
      initialEnd: end,
      selectedCalendarIds: _selectedCalendarIds(),
    );
    if (!mounted) {
      return;
    }
    context.read<DashboardDayMarkersRepository>().invalidate();
    await _loadData();
    context.read<DashboardBloc>().add(const LoadDashboardData());
  }

  Future<void> _openEventDetail(CalendarEvent event, DateTime day) async {
    await DashboardScreen.openEventDetail(
      context,
      event: event,
      selectedDate: day,
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openEditEvent(CalendarEvent event) async {
    await DashboardScreen.openEditCalendarEventSheet(
      context,
      event: event,
      selectedCalendarIds: _selectedCalendarIds(),
    );
    if (!mounted) {
      return;
    }
    context.read<DashboardDayMarkersRepository>().invalidate();
    await _loadData();
    context.read<DashboardBloc>().add(const LoadDashboardData());
  }

  String _rangeTitle(BuildContext context) {
    final DateFormat format = L10n.dateFormat('d MMM', context: context);
    switch (_mode) {
      case _CalendarGridMode.day:
        return format.format(_rangeStart);
      case _CalendarGridMode.threeDays:
        final DateTime end = _rangeStart.add(const Duration(days: 2));
        return '${format.format(_rangeStart)} – ${format.format(end)}';
      case _CalendarGridMode.week:
        final DateTime weekEnd = _rangeStart.add(const Duration(days: 6));
        return '${format.format(_rangeStart)} – ${format.format(weekEnd)}';
      case _CalendarGridMode.month:
        return L10n.dateFormat('MMMM yyyy', context: context)
            .format(_focusedMonth);
    }
  }

  int get _navigationStepDays => switch (_mode) {
        _CalendarGridMode.day => 1,
        _CalendarGridMode.threeDays => 3,
        _CalendarGridMode.week => 7,
        _CalendarGridMode.month => 0,
      };

  @override
  Widget build(BuildContext context) {
    final bool showTimeNav = _mode != _CalendarGridMode.month;

    return Scaffold(
      appBar: AppBar(
        title: Text('calendar_grid_title'.tr()),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'dashboard_tooltip_refresh'.tr(),
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_CalendarGridMode>(
              segments: <ButtonSegment<_CalendarGridMode>>[
                ButtonSegment<_CalendarGridMode>(
                  value: _CalendarGridMode.day,
                  label: Text('calendar_grid_day'.tr()),
                  icon: const Icon(Icons.view_day_outlined),
                ),
                ButtonSegment<_CalendarGridMode>(
                  value: _CalendarGridMode.threeDays,
                  label: Text('calendar_grid_three_days'.tr()),
                  icon: const Icon(Icons.view_column_outlined),
                ),
                ButtonSegment<_CalendarGridMode>(
                  value: _CalendarGridMode.week,
                  label: Text('calendar_grid_week'.tr()),
                  icon: const Icon(Icons.view_week_outlined),
                ),
                ButtonSegment<_CalendarGridMode>(
                  value: _CalendarGridMode.month,
                  label: Text('calendar_grid_month'.tr()),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: <_CalendarGridMode>{_mode},
              onSelectionChanged: (Set<_CalendarGridMode> selected) {
                if (selected.isNotEmpty) {
                  _setMode(selected.first);
                }
              },
            ),
          ),
          if (showTimeNav)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'calendar_grid_prev_period'.tr(),
                    onPressed: _loading
                        ? null
                        : () => _shiftRange(-_navigationStepDays),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _rangeTitle(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'calendar_grid_next_period'.tr(),
                    onPressed: _loading
                        ? null
                        : () => _shiftRange(_navigationStepDays),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _loadError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _mode == _CalendarGridMode.month
                    ? CalendarGridMonthView(
                        focusedDay: _focusedMonth,
                        dayMarkers: _dayMarkers,
                        onDaySelected: _onMonthDaySelected,
                        onPageChanged: _onMonthPageChanged,
                      )
                    : CalendarGridWeekView(
                        rangeStart: _rangeStart,
                        dayCount: _timeViewDayCount,
                        events: _storedEvents,
                        onEmptySlotLongPress: _openCreateFromSlot,
                        onEventTap: _openEventDetail,
                        onEventLongPress: _openEditEvent,
                      ),
          ),
        ],
      ),
    );
  }
}
