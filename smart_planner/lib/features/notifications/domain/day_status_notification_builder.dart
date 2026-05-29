import 'package:intl/intl.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/event_time_status.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_content.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Builds localized foreground-notification copy for today's tasks and events.
abstract final class DayStatusNotificationBuilder {
  DayStatusNotificationBuilder._();

  static DayStatusNotificationContent build({
    required List<Task> activeTasks,
    required List<Task> completedTasks,
    required List<Task> backlogTasks,
    required List<CalendarEvent> calendarEvents,
    DateTime? now,
  }) {
    final DateTime clock = now ?? DateTime.now();
    final int done = completedTasks.length;
    final int total = activeTasks.length + done;

    final String title = total == 0
        ? L10n.tr('day_status_notification_title_plain')
        : L10n.tr(
            'day_status_notification_title',
            namedArgs: <String, String>{
              'done': '$done',
              'total': '$total',
            },
          );

    final String body = _composeBody(
      events: calendarEvents,
      backlogCount: backlogTasks.length,
      now: clock,
    );

    return DayStatusNotificationContent(title: title, body: body);
  }

  static String _composeBody({
    required List<CalendarEvent> events,
    required int backlogCount,
    required DateTime now,
  }) {
    final String eventLine = _eventLine(events: events, now: now);
    if (backlogCount == 0) {
      return eventLine;
    }
    final String backlogLine = L10n.tr(
      'day_status_notification_backlog',
      namedArgs: <String, String>{'count': '$backlogCount'},
    );
    return '$eventLine\n$backlogLine';
  }

  static String _eventLine({
    required List<CalendarEvent> events,
    required DateTime now,
  }) {
    if (events.isEmpty) {
      return L10n.tr('day_status_notification_no_events');
    }

    final DateFormat timeFormat = L10n.dateFormat('Hm');

    for (final CalendarEvent event in events) {
      if (EventTimeStatusResolver.resolve(
            event: event,
            selectedDay: now,
            now: now,
          ) ==
          EventTimeStatus.current) {
        return L10n.tr(
          'day_status_notification_now',
          namedArgs: <String, String>{
            'title': event.title,
            'until': timeFormat.format(event.end),
          },
        );
      }
    }

    CalendarEvent? next;
    for (final CalendarEvent event in events) {
      if (event.start.isAfter(now)) {
        next = event;
        break;
      }
    }

    if (next != null) {
      return L10n.tr(
        'day_status_notification_next',
        namedArgs: <String, String>{
          'title': next.title,
          'from': timeFormat.format(next.start),
        },
      );
    }

    final CalendarEvent last = events.last;
    if (AppDateUtils.isSameCalendarDay(last.end, now) && last.end.isBefore(now)) {
      return L10n.tr('day_status_notification_events_done');
    }

    return L10n.tr('day_status_notification_no_events');
  }
}
