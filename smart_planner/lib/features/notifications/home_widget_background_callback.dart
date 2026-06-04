import 'package:smart_planner/features/deep_links/domain/deep_link_action.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_parser.dart';
import 'package:smart_planner/features/notifications/data/day_status_background_sync.dart';

/// Background handler for home-widget taps (no Activity launch).
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  final DeepLinkAction? action = DeepLinkParser.parse(uri);
  if (action is DeepLinkRefreshWidgetAction) {
    await DayStatusBackgroundSync.run();
  }
}
