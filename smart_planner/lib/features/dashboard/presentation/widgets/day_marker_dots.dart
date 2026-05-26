import 'package:flutter/material.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';

/// Compact calendar/task activity dots (dashboard strip & month grid).
class DayMarkerDots extends StatelessWidget {
  const DayMarkerDots({
    required this.marker,
    this.dotSize = 3.5,
    super.key,
  });

  final DayActivityMarker marker;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (!marker.hasAnyIndicator) {
      return SizedBox(height: dotSize);
    }

    final List<Widget> dots = <Widget>[];
    if (marker.hasCalendarEvents) {
      dots.add(_MarkerDot(
        color: _calendarDotColor(marker.calendarColorValue, colors),
        size: dotSize,
      ));
    }
    if (marker.hasLocalTasks) {
      dots.add(_MarkerDot(
        color: colors.secondary,
        size: dotSize,
      ));
    }

    return SizedBox(
      height: dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < dots.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 3),
            dots[i],
          ],
        ],
      ),
    );
  }

  static Color _calendarDotColor(int? colorValue, ColorScheme colors) {
    if (colorValue == null) {
      return colors.primary;
    }
    if (colorValue > 0xFFFFFF) {
      return Color(colorValue);
    }
    return Color(0xFF000000 | colorValue);
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
