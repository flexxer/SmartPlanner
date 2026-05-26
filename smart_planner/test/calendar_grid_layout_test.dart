import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_grid_layout.dart';

void main() {
  group('CalendarGridLayout', () {
    test('topOffsetForTime places noon at half timeline height', () {
      const double hourHeight = 60;
      final double top = CalendarGridLayout.topOffsetForTime(
        DateTime(2026, 5, 25, 12, 0),
        hourHeight,
      );
      expect(top, CalendarGridLayout.dayTimelineHeight(hourHeight) / 2);
    });

    test('slotFromLocalY maps tap at top to midnight', () {
      final DateTime day = DateTime(2026, 5, 25);
      final ({DateTime start, DateTime end}) slot =
          CalendarGridLayout.slotFromLocalY(
        day: day,
        localY: 0,
        hourHeight: CalendarGridLayout.defaultHourHeight,
      );
      expect(slot.start.hour, 0);
      expect(slot.start.minute, 0);
      expect(slot.end.difference(slot.start).inHours, 1);
    });
  });
}
