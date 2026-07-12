import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';

import 'package:smart_planner/core/localization/l10n.dart';

import 'package:smart_planner/core/utils/app_date_utils.dart';

import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';

import 'package:smart_planner/features/categories/domain/entities/category.dart';

import 'package:smart_planner/features/categories/presentation/widgets/category_badge_chip.dart';

import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';

import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';

import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';

import 'package:smart_planner/features/todo_list/presentation/widgets/task_badge.dart';

import 'package:smart_planner/features/todo_list/presentation/widgets/task_badge_labels.dart';

import 'package:smart_planner/features/todo_list/presentation/widgets/task_tile_list_context.dart';



/// Badge row for a [Task] on the dashboard tile or detail screen.

class TaskBadgesRow extends StatelessWidget {

  const TaskBadgesRow({

    required this.task,

    required this.selectedDate,

    required this.isOverdue,

    required this.listContext,

    required this.childTasksBundle,

    required this.attachments,

    this.visibleCalendarCount = 1,

    this.contextCalendar,

    this.linkedEvent,

    this.onOpenLinkedEvent,

    this.onLinkToCalendarEvent,

    this.onChildTasksBadgeTap,

    this.linkedEventMaxTitleLength = 20,

    this.categories = const <Category>[],

    super.key,

  });



  final Task task;

  final DateTime selectedDate;

  final bool isOverdue;

  final TaskTileListContext listContext;

  final ChildTasksBundle childTasksBundle;

  final List<TaskAttachment> attachments;

  final int visibleCalendarCount;

  final DeviceCalendarInfo? contextCalendar;

  final CalendarEvent? linkedEvent;

  final VoidCallback? onOpenLinkedEvent;

  final VoidCallback? onLinkToCalendarEvent;

  final VoidCallback? onChildTasksBadgeTap;

  final int linkedEventMaxTitleLength;

  final List<Category> categories;



  bool get _isDashboard => listContext != TaskTileListContext.detail;

  @override

  Widget build(BuildContext context) {

    final ColorScheme colors = Theme.of(context).colorScheme;

    final List<Widget> badges = <Widget>[];

    for (final Category category in categories) {
      badges.add(CategoryBadgeChip(category: category));
    }

    if (_contextCalendarBadge(context) case final Widget calendarBadge) {

      badges.add(calendarBadge);

    }

    if (_dueBadge(context, colors) case final Widget dueBadge) {

      badges.add(dueBadge);

    }

    badges.addAll(_linkedEntityBadges(context, colors));



    return Wrap(

      spacing: 6,

      runSpacing: 4,

      children: badges,

    );

  }



  bool _shouldShowDueBadge() {

    final DateTime? due = task.dueDate;

    switch (listContext) {

      case TaskTileListContext.dashboardDueOnSelectedDay:

        if (due == null) {

          return false;

        }

        return !AppDateUtils.isSameCalendarDay(due, selectedDate);

      case TaskTileListContext.dashboardBacklog:

        return due != null;

      case TaskTileListContext.dashboardOverdue:

        return due != null || isOverdue;

      case TaskTileListContext.detail:

        return false;

    }

  }



  String _dueLabel(BuildContext context) {

    final DateTime? due = task.dueDate;

    if (listContext == TaskTileListContext.dashboardOverdue && isOverdue) {

      final String datePart = due != null

          ? L10n.dateFormat('d MMM yyyy', context: context).format(due)

          : 'no_due_date'.tr();

      return '$datePart · ${L10n.overdueDays(task.dynamicOverdueDays)}';

    }

    return taskDueBadgeLabel(context, task, selectedDate);

  }



  Widget? _dueBadge(BuildContext context, ColorScheme colors) {

    if (!_shouldShowDueBadge()) {

      return null;

    }

    return TaskBadge(

      label: _dueLabel(context),

      backgroundColor:

          isOverdue ? colors.errorContainer : colors.primaryContainer,

      foregroundColor:

          isOverdue ? colors.onErrorContainer : colors.onPrimaryContainer,

      icon: Icons.event_outlined,

    );

  }



  Widget? _contextCalendarBadge(BuildContext context) {

    if (visibleCalendarCount <= 1) {

      return null;

    }

    final String calendarId = task.calendarId.trim();

    if (calendarId.isEmpty) {

      return null;

    }



    final DeviceCalendarInfo? info = contextCalendar;

    final String label = info?.name ?? calendarId;

    final ({Color background, Color foreground}) badgeColors =

        CalendarContextColors.badgeColorsFor(

      context,

      calendarId: calendarId,

      fallbackColorValue: info?.colorValue,

    );



    return TaskBadge(

      label: label,

      backgroundColor: badgeColors.background,

      foregroundColor: badgeColors.foreground,

      icon: Icons.calendar_month_outlined,

    );

  }



  List<Widget> _linkedEntityBadges(BuildContext context, ColorScheme colors) {

    final List<Widget> badges = <Widget>[];



    if (linkedEvent != null) {

      badges.add(

        TaskBadge(

          label: linkedEventBadgeLabel(

            linkedEvent!,

            maxLength: linkedEventMaxTitleLength,

          ),

          backgroundColor: colors.secondaryContainer,

          foregroundColor: colors.onSecondaryContainer,

          icon: Icons.event,

          onTap: onOpenLinkedEvent,

        ),

      );

    } else if (!_isDashboard && onLinkToCalendarEvent != null) {

      badges.add(

        TaskBadge(

          label: 'task_to_event'.tr(),

          backgroundColor: colors.secondaryContainer,

          foregroundColor: colors.onSecondaryContainer,

          icon: Icons.link,

          onTap: onLinkToCalendarEvent,

        ),

      );

    }



    if (childTaskProgressBadgeLabel(childTasksBundle) case final String progress) {

      badges.add(

        TaskBadge(

          label: progress,

          backgroundColor: colors.tertiaryContainer,

          foregroundColor: colors.onTertiaryContainer,

          icon: Icons.account_tree,

          onTap: onChildTasksBadgeTap,

        ),

      );

    }



    if (checklistAttachmentProgressBadgeLabel(attachments)

        case final String checklistProgress) {

      badges.add(

        TaskBadge(

          label: checklistProgress,

          backgroundColor: colors.secondaryContainer,

          foregroundColor: colors.onSecondaryContainer,

          icon: Icons.fact_check,

        ),

      );

    }



    if (nonChecklistAttachmentCountBadgeLabel(attachments)

        case final String attachCount) {

      badges.add(

        TaskBadge(

          label: attachCount,

          backgroundColor: colors.primaryContainer,

          foregroundColor: colors.onPrimaryContainer,

          icon: Icons.attach_file,

        ),

      );

    }



    return badges;

  }

}


