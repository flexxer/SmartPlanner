/// Serializable home-screen widget state (Android RemoteViews).
class DayStatusWidgetPayload {
  const DayStatusWidgetPayload({
    required this.dateLabel,
    required this.headerTitle,
    required this.progressPercent,
    required this.nowVisible,
    required this.nowTimeRange,
    required this.nowTitle,
    required this.nextEvents,
    required this.tasksSectionTitle,
    required this.taskRows,
    required this.footerText,
    required this.eventsEmptyText,
  });

  final String dateLabel;
  final String headerTitle;

  /// 0–100, or `-1` to hide the progress bar.
  final int progressPercent;

  final bool nowVisible;
  final String nowTimeRange;
  final String nowTitle;

  /// Up to two upcoming events after the current one: `time\ttitle`.
  final List<String> nextEvents;

  final String tasksSectionTitle;

  /// Each row: `taskId\tcompleted(0|1)\ttitle`.
  final List<String> taskRows;

  final String footerText;
  final String eventsEmptyText;

  Map<String, String> toWidgetData() {
    final Map<String, String> data = <String, String>{
      'dw_date_label': dateLabel,
      'dw_header_title': headerTitle,
      'dw_progress_percent': '$progressPercent',
      'dw_now_visible': nowVisible ? '1' : '0',
      'dw_now_time': nowTimeRange,
      'dw_now_title': nowTitle,
      'dw_tasks_section': tasksSectionTitle,
      'dw_footer': footerText,
      'dw_events_empty': eventsEmptyText,
      'dw_next_count': '${nextEvents.length}',
    };

    for (int i = 0; i < 2; i++) {
      if (i < nextEvents.length) {
        data['dw_next$i'] = nextEvents[i];
      } else {
        data['dw_next$i'] = '';
      }
    }

    for (int i = 0; i < 3; i++) {
      if (i < taskRows.length) {
        data['dw_task$i'] = taskRows[i];
      } else {
        data['dw_task$i'] = '';
      }
    }

    return data;
  }
}
