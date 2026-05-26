import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';

/// Settings toggle for the Android ongoing day-status foreground notification.
class DayStatusBarSettingsSection extends StatefulWidget {
  const DayStatusBarSettingsSection({super.key});

  @override
  State<DayStatusBarSettingsSection> createState() =>
      _DayStatusBarSettingsSectionState();
}

class _DayStatusBarSettingsSectionState extends State<DayStatusBarSettingsSection> {
  bool? _enabled;
  bool _busy = false;

  static bool get isSupported =>
      !kIsWeb && !Platform.isIOS && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    if (isSupported) {
      _load();
    }
  }

  Future<void> _load() async {
    final bool enabled = await context
        .read<NotificationPreferencesRepository>()
        .isDayStatusBarEnabled();
    if (mounted) {
      setState(() => _enabled = enabled);
    }
  }

  Future<void> _onChanged(bool value) async {
    setState(() {
      _enabled = value;
      _busy = true;
    });
    await context.read<DayStatusNotificationController>().setDayStatusBarEnabled(
          value,
        );
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return const SizedBox.shrink();
    }

    return SwitchListTile(
      title: Text('settings_day_status_bar_title'.tr()),
      subtitle: Text('settings_day_status_bar_subtitle'.tr()),
      value: _enabled ?? false,
      onChanged: _busy || _enabled == null ? null : _onChanged,
    );
  }
}
