import 'package:intl/intl.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/event_time_status.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Builds [DayStatusWidgetPayload] from [DayStatusTodaySnapshot].
abstract final class DayStatusWidgetPayloadBuilder {
  DayStatusWidgetPayloadBuilder._();

  static const int _maxNextEvents = 2;
  static const int _maxTaskRows = 3;
  static const int _maxBacklogPreview = 2;

  static DayStatusWidgetPayload build(DayStatusTodaySnapshot snapshot) {
    final DateTime now = snapshot.now;
    final int done = snapshot.completedTasks.length;
    final int total = snapshot.activeTasks.length + done;

    final String headerTitle = total == 0
        ? L10n.tr('day_status_notification_title_plain')
        : L10n.tr(
            'day_status_notification_title',
            namedArgs: <String, String>{
              'done': '$done',
              'total': '$total',
            },
          );

    final int progressPercent = total == 0 ? -1 : ((done * 100) / total).round();

    final DateFormat timeFormat = L10n.dateFormat('Hm');
    final _EventSlice events = _sliceEvents(
      events: snapshot.calendarEvents,
      now: now,
      timeFormat: timeFormat,
    );

    final List<Task> taskPreview = snapshot.activeTasks.take(_maxTaskRows).toList();
    final List<String> taskRows = taskPreview
        .map(
          (Task t) => '${t.id}\t${t.isCompleted ? 1 : 0}\t${t.title}',
        )
        .toList(growable: false);

    final String footer = _footerText(
      backlogCount: snapshot.backlogTasks.length,
      backlogTasks: snapshot.backlogTasks,
      overdueCount: snapshot.overdueTasks.length,
    );

    return DayStatusWidgetPayload(
      dateLabel: _dateLabel(now),
      headerTitle: headerTitle,
      progressPercent: progressPercent,
      nowVisible: events.nowTitle.isNotEmpty,
      nowTimeRange: events.nowTimeRange,
      nowTitle: events.nowTitle,
      nextEvents: events.nextLines,
      tasksSectionTitle: L10n.tr('dashboard_due_section_today'),
      taskRows: taskRows,
      footerText: footer,
      eventsEmptyText: L10n.tr('day_status_notification_no_events'),
    );
  }

  static String _dateLabel(DateTime now) {
    if (AppDateUtils.isToday(now)) {
      return L10n.tr('common_today');
    }
    return L10n.dateFormat('EEE, d MMM').format(now);
  }

  static String _footerText({
    required int backlogCount,
    required List<Task> backlogTasks,
    required int overdueCount,
  }) {
    final List<String> parts = <String>[];

    if (backlogCount > 0) {
      final String preview = backlogTasks
          .take(_maxBacklogPreview)
          .map((Task t) => t.title)
          .join(' · ');
      final String countLine = L10n.tr(
        'day_status_notification_backlog',
        namedArgs: <String, String>{'count': '$backlogCount'},
      );
      parts.add(preview.isEmpty ? countLine : '$countLine — $preview');
    }

    if (overdueCount > 0) {
      parts.add(
        L10n.tr(
          'overdue_section',
          namedArgs: <String, String>{'count': '$overdueCount'},
        ),
      );
    }

    if (parts.isEmpty) {
      return L10n.tr('widget_footer_open');
    }

    return '${parts.join(' · ')}\n${L10n.tr('widget_footer_open')}';
  }

  static _EventSlice _sliceEvents({
    required List<CalendarEvent> events,
    required DateTime now,
    required DateFormat timeFormat,
  }) {
    if (events.isEmpty) {
      return const _EventSlice();
    }

    CalendarEvent? current;
    final List<CalendarEvent> upcoming = <CalendarEvent>[];

    for (final CalendarEvent event in events) {
      final EventTimeStatus status = EventTimeStatusResolver.resolve(
        event: event,
        selectedDay: now,
        now: now,
      );
      if (status == EventTimeStatus.current) {
        current = event;
      } else if (status == EventTimeStatus.future) {
        upcoming.add(event);
      }
    }

    if (current != null) {
      final String nowTime =
          '${timeFormat.format(current.start)}–${timeFormat.format(current.end)}';
      final List<String> nextLines = upcoming
          .take(_maxNextEvents)
          .map(
            (CalendarEvent e) =>
                '${timeFormat.format(e.start)}\t${e.title}',
          )
          .toList(growable: false);
      return _EventSlice(
        nowTimeRange: nowTime,
        nowTitle: current.title,
        nextLines: nextLines,
      );
    }

    if (upcoming.isNotEmpty) {
      final CalendarEvent next = upcoming.first;
      final List<String> nextLines = upcoming
          .take(_maxNextEvents)
          .map(
            (CalendarEvent e) =>
                '${timeFormat.format(e.start)}\t${e.title}',
          )
          .toList(growable: false);
      return _EventSlice(
        nowTimeRange: timeFormat.format(next.start),
        nowTitle: next.title,
        nextLines: nextLines.length > 1 ? nextLines.sublist(1) : const <String>[],
      );
    }

    final CalendarEvent last = events.last;
    if (AppDateUtils.isSameCalendarDay(last.end, now) && last.end.isBefore(now)) {
      return _EventSlice(
        nowTitle: L10n.tr('day_status_notification_events_done'),
      );
    }

    return const _EventSlice();
  }
}

class _EventSlice {
  const _EventSlice({
    this.nowTimeRange = '',
    this.nowTitle = '',
    this.nextLines = const <String>[],
  });

  final String nowTimeRange;
  final String nowTitle;
  final List<String> nextLines;
}
