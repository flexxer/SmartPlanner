import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Due-date label for task badges (dashboard tile and detail screen).
String taskDueBadgeLabel(
  BuildContext context,
  Task task,
  DateTime selectedDate,
) {
  final DateTime? due = task.dueDate;
  if (due == null) {
    return 'no_due_date'.tr();
  }
  if (AppDateUtils.isSameCalendarDay(due, selectedDate) &&
      AppDateUtils.isToday(selectedDate)) {
    return 'due_today'.tr();
  }
  return L10n.dateFormat('d MMM yyyy', context: context).format(due);
}

/// Linked event title for badges; [maxLength] includes ellipsis when truncated.
String linkedEventBadgeLabel(
  CalendarEvent event, {
  int maxLength = 20,
}) {
  final String title = event.title.trim();
  if (title.isEmpty) {
    return 'task_event_fallback'.tr();
  }
  if (title.length <= maxLength) {
    return title;
  }
  final int cut = maxLength > 2 ? maxLength - 2 : maxLength;
  return '${title.substring(0, cut)}…';
}
