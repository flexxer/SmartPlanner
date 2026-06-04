import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/domain/day_status_locale_copy.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';

/// Builds [DayStatusWidgetPayload] from [DayStatusTodaySnapshot] (foreground/tests).
abstract final class DayStatusWidgetPayloadBuilder {
  DayStatusWidgetPayloadBuilder._();

  static DayStatusWidgetPayload build(
    DayStatusTodaySnapshot snapshot, {
    String languageCode = 'en',
  }) =>
      DayStatusLocaleCopy.widgetPayload(
        snapshot: snapshot,
        languageCode: languageCode,
      );
}
