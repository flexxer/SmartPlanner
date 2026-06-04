import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/background_service.dart';

/// Toggles for morning and evening task digest notifications.
class TaskDigestSettingsSection extends StatefulWidget {
  const TaskDigestSettingsSection({super.key});

  @override
  State<TaskDigestSettingsSection> createState() =>
      _TaskDigestSettingsSectionState();
}

class _TaskDigestSettingsSectionState extends State<TaskDigestSettingsSection> {
  bool? _morningEnabled;
  bool? _eveningEnabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final NotificationPreferencesRepository prefs =
        context.read<NotificationPreferencesRepository>();
    final bool morning = await prefs.isMorningDigestEnabled();
    final bool evening = await prefs.isEveningDigestEnabled();
    if (mounted) {
      setState(() {
        _morningEnabled = morning;
        _eveningEnabled = evening;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: Text('settings_morning_digest_title'.tr()),
          subtitle: Text('settings_morning_digest_subtitle'.tr()),
          value: _morningEnabled ?? true,
          onChanged: _morningEnabled == null
              ? null
              : (bool value) async {
                  setState(() => _morningEnabled = value);
                  await context
                      .read<NotificationPreferencesRepository>()
                      .setMorningDigestEnabled(value);
                  if (value) {
                    await BackgroundTaskService.scheduleNextMorningDigest();
                  }
                },
        ),
        SwitchListTile(
          title: Text('settings_evening_digest_title'.tr()),
          subtitle: Text('settings_evening_digest_subtitle'.tr()),
          value: _eveningEnabled ?? true,
          onChanged: _eveningEnabled == null
              ? null
              : (bool value) async {
                  setState(() => _eveningEnabled = value);
                  await context
                      .read<NotificationPreferencesRepository>()
                      .setEveningDigestEnabled(value);
                  if (value) {
                    await BackgroundTaskService.scheduleNextEveningDigest();
                  }
                },
        ),
      ],
    );
  }
}
