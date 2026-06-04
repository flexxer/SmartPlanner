import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/event_time_status.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_content.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Locale-aware day-status strings for background isolates (no [BuildContext]).
abstract final class DayStatusLocaleCopy {
  DayStatusLocaleCopy._();

  static const int _maxNextEvents = 2;
  static const int _maxTaskRows = 3;
  static const int _maxBacklogPreview = 2;

  static DayStatusNotificationContent notificationContent({
    required DayStatusTodaySnapshot snapshot,
    required String languageCode,
  }) {
    final _Strings s = _Strings.forCode(languageCode);
    final int done = snapshot.completedTasks.length;
    final int total = snapshot.activeTasks.length + done;

    final String title = total == 0
        ? s.titlePlain
        : s.titleProgress(done: done, total: total);

    final String body = _notificationBody(
      strings: s,
      events: snapshot.calendarEvents,
      backlogCount: snapshot.backlogTasks.length,
      now: snapshot.now,
      languageCode: languageCode,
    );

    return DayStatusNotificationContent(title: title, body: body);
  }

  static DayStatusWidgetPayload widgetPayload({
    required DayStatusTodaySnapshot snapshot,
    required String languageCode,
  }) {
    final _Strings s = _Strings.forCode(languageCode);
    final DateTime now = snapshot.now;
    final int done = snapshot.completedTasks.length;
    final int total = snapshot.activeTasks.length + done;

    final String headerTitle = total == 0
        ? s.titlePlain
        : s.titleProgress(done: done, total: total);
    final int progressPercent = total == 0 ? -1 : ((done * 100) / total).round();

    final DateFormat timeFormat = DateFormat('Hm', languageCode);
    final _EventSlice events = _sliceEvents(
      events: snapshot.calendarEvents,
      now: now,
      timeFormat: timeFormat,
      strings: s,
    );

    final List<String> taskRows = snapshot.activeTasks
        .take(_maxTaskRows)
        .map(
          (Task t) => '${t.id}\t${t.isCompleted ? 1 : 0}\t${t.title}',
        )
        .toList(growable: false);

    return DayStatusWidgetPayload(
      dateLabel: _dateLabel(now, s),
      headerTitle: headerTitle,
      progressPercent: progressPercent,
      nowVisible: events.nowTitle.isNotEmpty,
      nowLabel: s.nowSectionLabel,
      nowTimeRange: events.nowTimeRange,
      nowTitle: events.nowTitle,
      nextEvents: events.nextLines,
      tasksSectionTitle: s.tasksSectionToday,
      taskRows: taskRows,
      footerText: _footerText(
        strings: s,
        backlogCount: snapshot.backlogTasks.length,
        backlogTasks: snapshot.backlogTasks,
        overdueCount: snapshot.overdueTasks.length,
      ),
      eventsEmptyText: s.noEvents,
    );
  }

  static String _dateLabel(DateTime now, _Strings strings) {
    if (AppDateUtils.isToday(now)) {
      return strings.today;
    }
    return DateFormat('EEE, d MMM', strings.languageCode).format(now);
  }

  static String _notificationBody({
    required _Strings strings,
    required List<CalendarEvent> events,
    required int backlogCount,
    required DateTime now,
    required String languageCode,
  }) {
    final String eventLine = _eventLine(
      strings: strings,
      events: events,
      now: now,
      languageCode: languageCode,
    );
    if (backlogCount == 0) {
      return eventLine;
    }
    return '$eventLine\n${strings.backlog(backlogCount)}';
  }

  static String _eventLine({
    required _Strings strings,
    required List<CalendarEvent> events,
    required DateTime now,
    required String languageCode,
  }) {
    if (events.isEmpty) {
      return strings.noEvents;
    }

    final DateFormat timeFormat = DateFormat('Hm', languageCode);

    for (final CalendarEvent event in events) {
      if (EventTimeStatusResolver.resolve(
            event: event,
            selectedDay: now,
            now: now,
          ) ==
          EventTimeStatus.current) {
        return strings.now(
          title: event.title,
          until: timeFormat.format(event.end),
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
      return strings.next(
        title: next.title,
        from: timeFormat.format(next.start),
      );
    }

    final CalendarEvent last = events.last;
    if (AppDateUtils.isSameCalendarDay(last.end, now) && last.end.isBefore(now)) {
      return strings.eventsDone;
    }

    return strings.noEvents;
  }

  static String _footerText({
    required _Strings strings,
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
      final String countLine = strings.backlog(backlogCount);
      parts.add(preview.isEmpty ? countLine : '$countLine — $preview');
    }

    if (overdueCount > 0) {
      parts.add(strings.overdueSection(overdueCount));
    }

    if (parts.isEmpty) {
      return strings.widgetOpen;
    }

    return '${parts.join(' · ')}\n${strings.widgetOpen}';
  }

  static _EventSlice _sliceEvents({
    required List<CalendarEvent> events,
    required DateTime now,
    required DateFormat timeFormat,
    required _Strings strings,
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
        nextLines: nextLines.length > 1
            ? nextLines.sublist(1)
            : const <String>[],
      );
    }

    final CalendarEvent last = events.last;
    if (AppDateUtils.isSameCalendarDay(last.end, now) && last.end.isBefore(now)) {
      return _EventSlice(nowTitle: strings.eventsDone);
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

class _Strings {
  const _Strings({
    required this.languageCode,
    required this.titlePlain,
    required this.today,
    required this.noEvents,
    required this.eventsDone,
    required this.tasksSectionToday,
    required this.nowSectionLabel,
    required this.widgetOpen,
    required this.titleProgressTemplate,
    required this.nowTemplate,
    required this.nextTemplate,
    required this.backlogTemplate,
    required this.overdueSectionTemplate,
  });

  final String languageCode;
  final String titlePlain;
  final String today;
  final String noEvents;
  final String eventsDone;
  final String tasksSectionToday;
  final String nowSectionLabel;
  final String widgetOpen;
  final String titleProgressTemplate;
  final String nowTemplate;
  final String nextTemplate;
  final String backlogTemplate;
  final String overdueSectionTemplate;

  String titleProgress({required int done, required int total}) =>
      titleProgressTemplate
          .replaceAll('{done}', '$done')
          .replaceAll('{total}', '$total');

  String now({required String title, required String until}) =>
      nowTemplate.replaceAll('{title}', title).replaceAll('{until}', until);

  String next({required String title, required String from}) =>
      nextTemplate.replaceAll('{title}', title).replaceAll('{from}', from);

  String backlog(int count) =>
      backlogTemplate.replaceAll('{count}', '$count');

  String overdueSection(int count) =>
      overdueSectionTemplate.replaceAll('{count}', '$count');

  static _Strings forCode(String code) {
    return switch (code) {
      'ru' => const _Strings(
          languageCode: 'ru',
          titlePlain: 'Планы на сегодня',
          today: 'Сегодня',
          noEvents: 'На сегодня событий в календаре нет',
          eventsDone: 'На сегодня событий больше нет',
          tasksSectionToday: 'Задачи со сроком на сегодня',
          nowSectionLabel: 'СЕЙЧАС',
          widgetOpen: 'Открыть',
          titleProgressTemplate: 'Планы на сегодня: ✓ {done} / {total} задач',
          nowTemplate: 'Сейчас: {title} (до {until})',
          nextTemplate: 'Далее: {title} (с {from})',
          backlogTemplate: 'Без срока: {count}',
          overdueSectionTemplate: 'Просрочено ({count})',
        ),
      'es' => const _Strings(
          languageCode: 'es',
          titlePlain: 'Plan de hoy',
          today: 'Hoy',
          noEvents: 'No hay eventos de calendario hoy',
          eventsDone: 'No hay más eventos hoy',
          tasksSectionToday: 'Tareas con fecha para hoy',
          nowSectionLabel: 'AHORA',
          widgetOpen: 'Abrir',
          titleProgressTemplate: 'Plan de hoy: ✓ {done} / {total} tareas',
          nowTemplate: 'Ahora: {title} (hasta {until})',
          nextTemplate: 'Próximo: {title} (desde {from})',
          backlogTemplate: 'Backlog: {count}',
          overdueSectionTemplate: 'Atrasadas ({count})',
        ),
      _ => const _Strings(
          languageCode: 'en',
          titlePlain: "Today's plan",
          today: 'Today',
          noEvents: 'No calendar events for today',
          eventsDone: 'No more events today',
          tasksSectionToday: 'Tasks due today',
          nowSectionLabel: 'NOW',
          widgetOpen: 'Open',
          titleProgressTemplate: "Today's plan: ✓ {done} / {total} tasks",
          nowTemplate: 'Now: {title} (until {until})',
          nextTemplate: 'Next: {title} (from {from})',
          backlogTemplate: 'Backlog: {count}',
          overdueSectionTemplate: 'Overdue ({count})',
        ),
    };
  }
}
