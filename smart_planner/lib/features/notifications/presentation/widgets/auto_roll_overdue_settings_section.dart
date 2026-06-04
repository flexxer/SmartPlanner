import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';

/// Toggle for automatic midnight roll of overdue tasks to today.
class AutoRollOverdueSettingsSection extends StatefulWidget {
  const AutoRollOverdueSettingsSection({super.key});

  @override
  State<AutoRollOverdueSettingsSection> createState() =>
      _AutoRollOverdueSettingsSectionState();
}

class _AutoRollOverdueSettingsSectionState
    extends State<AutoRollOverdueSettingsSection> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final NotificationPreferencesRepository prefs =
        context.read<NotificationPreferencesRepository>();
    final bool enabled = await prefs.isAutoRollOverdueAtMidnightEnabled();
    if (mounted) {
      setState(() => _enabled = enabled);
    }
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _enabled = value);
    await context
        .read<NotificationPreferencesRepository>()
        .setAutoRollOverdueAtMidnightEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = _enabled ?? true;

    return SwitchListTile(
      title: Text('settings_auto_roll_overdue_title'.tr()),
      subtitle: Text('settings_auto_roll_overdue_subtitle'.tr()),
      value: enabled,
      onChanged: _enabled == null ? null : _onChanged,
    );
  }
}
