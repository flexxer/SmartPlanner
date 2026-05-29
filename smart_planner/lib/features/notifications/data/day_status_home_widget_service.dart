import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload_builder.dart';

/// Pushes today's snapshot to the Android home-screen widget.
class DayStatusHomeWidgetService {
  DayStatusHomeWidgetService({required DayStatusTodayLoader loader})
      : _loader = loader;

  static const String androidProviderName =
      'com.aliakseipcholkin.smart_planner.DayLinxWidgetProvider';

  final DayStatusTodayLoader _loader;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> syncToday() async {
    if (!isSupported) {
      return;
    }

    try {
      final DayStatusTodaySnapshot snapshot = await _loader.load();
      final DayStatusWidgetPayload payload =
          DayStatusWidgetPayloadBuilder.build(snapshot);
      await _pushPayload(payload);
    } catch (_) {
      // Widget update must not break the app.
    }
  }

  Future<void> _pushPayload(DayStatusWidgetPayload payload) async {
    final Map<String, String> data = payload.toWidgetData();
    for (final MapEntry<String, String> entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
    await HomeWidget.updateWidget(
      qualifiedAndroidName: androidProviderName,
    );
  }
}
