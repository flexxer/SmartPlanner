import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';

/// Android home screen widget bridge (see [DayStatusHomeWidgetService]).
abstract final class AndroidWidgetProvider {
  AndroidWidgetProvider._();

  /// Updates the widget from a pre-built [payload].
  static Future<void> updateFromPayload(DayStatusWidgetPayload payload) async {
    final Map<String, String> data = payload.toWidgetData();
    // Delegated to [DayStatusHomeWidgetService] in production; kept for tests.
    assert(data.isNotEmpty);
  }
}
