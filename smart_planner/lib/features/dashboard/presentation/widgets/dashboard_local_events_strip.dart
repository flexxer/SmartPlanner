import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/theme/app_color_utils.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_recurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/compressed_events_strip_layout.dart';
import 'package:smart_planner/features/dashboard/domain/event_time_status.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_badge.dart';

/// Horizontal strip of local calendar events with a live "now" timeline for today.
class DashboardLocalEventsStrip extends StatefulWidget {
  const DashboardLocalEventsStrip({
    required this.events,
    required this.selectedDate,
    required this.timeFormat,
    required this.onEventTap,
    required this.onEventLongPress,
    super.key,
  });

  final List<CalendarEvent> events;
  final DateTime selectedDate;
  final DateFormat timeFormat;
  final void Function(CalendarEvent event) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;

  static String linkedTasksLabel(int count) {
    if (count == 0) {
      return '0 задач';
    }
    final int mod10 = count % 10;
    final int mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return '$count задача';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return '$count задачи';
    }
    return '$count задач';
  }

  @override
  State<DashboardLocalEventsStrip> createState() =>
      _DashboardLocalEventsStripState();
}

class _DashboardLocalEventsStripState extends State<DashboardLocalEventsStrip> {
  static const double _stripHeight = 116;
  static const double _horizontalPadding = 16;

  final ScrollController _scrollController = ScrollController();
  Timer? _nowTimer;
  DateTime _now = DateTime.now();

  bool get _isToday =>
      AppDateUtils.isSameCalendarDay(widget.selectedDate, _now);

  CompressedEventsStripLayout get _layout =>
      CompressedEventsStripLayout.build(
        events: widget.events,
        selectedDate: widget.selectedDate,
        now: _now,
        isToday: _isToday,
      );

  @override
  void initState() {
    super.initState();
    _startNowTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToRelevantPosition();
    });
  }

  @override
  void didUpdateWidget(DashboardLocalEventsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool dateChanged = !AppDateUtils.isSameCalendarDay(
      oldWidget.selectedDate,
      widget.selectedDate,
    );
    final bool eventsChanged = oldWidget.events != widget.events;

    if (dateChanged) {
      _startNowTimer();
    }
    if (dateChanged || eventsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToRelevantPosition();
      });
    }
  }

  void _startNowTimer() {
    _nowTimer?.cancel();
    _now = DateTime.now();
    if (!_isToday) {
      return;
    }
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  void _scrollToRelevantPosition() {
    if (!_scrollController.hasClients) {
      return;
    }

    final double? focusLeft = _layout.focusScrollLeft;
    if (focusLeft == null) {
      return;
    }

    final double viewportWidth = _scrollController.position.viewportDimension;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double target = (focusLeft - viewportWidth * 0.25).clamp(0, maxScroll);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    final CompressedEventsStripLayout layout = _layout;

    return SizedBox(
      height: _stripHeight,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: SizedBox(
          width: layout.totalWidth,
          height: _stripHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final CompressedStripSegment segment in layout.segments)
                switch (segment) {
                  CompressedEventSegment(:final event, :final left, :final width) =>
                    Positioned(
                      left: left,
                      top: 0,
                      width: width,
                      child: _LocalEventCard(
                        event: event,
                        timeFormat: widget.timeFormat,
                        status: EventTimeStatusResolver.resolve(
                          event: event,
                          selectedDay: widget.selectedDate,
                          now: _now,
                        ),
                        onTap: () => widget.onEventTap(event),
                        onLongPress: () => widget.onEventLongPress(event),
                      ),
                    ),
                  CompressedGapSegment(:final from, :final to, :final left, :final width) =>
                    Positioned(
                      left: left,
                      top: 0,
                      width: width,
                      child: _TimeGapMarker(
                        label: CompressedEventsStripLayout.gapLabel(
                          to.difference(from),
                        ),
                      ),
                    ),
                },
              if (_isToday && layout.nowIndicatorLeft != null)
                Positioned(
                  left: layout.nowIndicatorLeft!,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: _NowTimeIndicator(
                      timeLabel: widget.timeFormat.format(_now),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact marker for a collapsed idle period between events.
class _TimeGapMarker extends StatelessWidget {
  const _TimeGapMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SizedBox(
      height: _DashboardLocalEventsStripState._stripHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '· · ·',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.outline,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '· · ·',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.outline,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowTimeIndicator extends StatefulWidget {
  const _NowTimeIndicator({required this.timeLabel});

  final String timeLabel;

  @override
  State<_NowTimeIndicator> createState() => _NowTimeIndicatorState();
}

class _NowTimeIndicatorState extends State<_NowTimeIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? timeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        );

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double opacity = 0.55 + _controller.value * 0.45;
        return Column(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.primary.withValues(alpha: opacity),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(widget.timeLabel, style: timeStyle),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                width: 2,
                color: colors.primary.withValues(alpha: opacity),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocalEventCard extends StatelessWidget {
  const _LocalEventCard({
    required this.event,
    required this.timeFormat,
    required this.status,
    required this.onTap,
    required this.onLongPress,
  });

  final CalendarEvent event;
  final DateFormat timeFormat;
  final EventTimeStatus status;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Start–end label for the strip card (no leading calendar icon).
  static String timeRangeLabel(CalendarEvent event, DateFormat format) {
    return '${format.format(event.start)} – ${format.format(event.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = CalendarContextColors.accentFor(
      context,
      calendarId: event.calendarId,
      fallbackColorValue: event.colorValue,
    );
    final bool isRecurring = CalendarEventRecurrence.hasRepeatingRule(event);
    final int linkedCount = event.linkedTaskIds.length;
    final bool isPast = status == EventTimeStatus.past;
    final bool isCurrent = status == EventTimeStatus.current;

    final Color cardColor = colors.surface;
    final double cardOpacity = isPast ? 0.55 : 1;
    final Color titleColor = isPast
        ? colors.onSurface.withValues(alpha: 0.55)
        : colors.onSurface;
    final Color timeColor = isPast
        ? AppColorUtils.accentLabel(accent, colors, muted: true)
        : AppColorUtils.accentLabel(accent, colors);

    return Opacity(
      opacity: cardOpacity,
      child: SizedBox(
        width: CompressedEventsStripLayout.cardWidth,
        child: Material(
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCurrent
                  ? colors.primary
                  : colors.outlineVariant,
              width: isCurrent ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(width: 5, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  timeRangeLabel(event, timeFormat),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: timeColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isRecurring)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.repeat,
                                    size: 14,
                                    color: colors.onSurfaceVariant.withValues(
                                      alpha: isPast ? 0.5 : 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (isCurrent) ...<Widget>[
                            const SizedBox(height: 4),
                            _NowChip(colors: colors),
                          ],
                          if (linkedCount > 0) ...<Widget>[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TaskBadge(
                                label: DashboardLocalEventsStrip
                                    .linkedTasksLabel(linkedCount),
                                backgroundColor: colors.secondaryContainer,
                                foregroundColor: colors.onSecondaryContainer,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NowChip extends StatefulWidget {
  const _NowChip({required this.colors});

  final ColorScheme colors;

  @override
  State<_NowChip> createState() => _NowChipState();
}

class _NowChipState extends State<_NowChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: widget.colors.primary.withValues(
              alpha: 0.12 + _pulse.value * 0.12,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.colors.primary.withValues(
                alpha: 0.5 + _pulse.value * 0.5,
              ),
            ),
          ),
          child: Text(
            'events_now_chip'.tr(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: widget.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      },
    );
  }
}
