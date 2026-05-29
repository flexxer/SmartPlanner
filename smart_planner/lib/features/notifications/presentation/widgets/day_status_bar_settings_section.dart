import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/notifications/data/day_status_notification_controller.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';

/// Settings toggles for the Android ongoing day-status foreground notification.
class DayStatusBarSettingsSection extends StatefulWidget {
  const DayStatusBarSettingsSection({super.key});

  static bool get isSupported =>
      !kIsWeb && !Platform.isIOS && Platform.isAndroid;

  @override
  State<DayStatusBarSettingsSection> createState() =>
      _DayStatusBarSettingsSectionState();
}

class _DayStatusBarSettingsSectionState extends State<DayStatusBarSettingsSection> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (DayStatusBarSettingsSection.isSupported) {
      _load();
    }
  }

  Future<void> _load() async {
    final NotificationPreferencesRepository prefs =
        context.read<NotificationPreferencesRepository>();
    final bool enabled = await prefs.isDayStatusBarEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
      });
    }
  }

  Future<void> _onEnabledChanged(bool value) async {
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
    if (!DayStatusBarSettingsSection.isSupported) {
      return const SizedBox.shrink();
    }

    final bool enabled = _enabled ?? false;
    final bool controlsEnabled = !_busy && _enabled != null;

    return Column(
      children: <Widget>[
        SwitchListTile(
          title: Text('settings_day_status_bar_title'.tr()),
          subtitle: Text('settings_day_status_bar_subtitle'.tr()),
          value: enabled,
          onChanged: controlsEnabled ? _onEnabledChanged : null,
        ),
      ],
    );
  }
}
