import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/reminder_picker_field.dart';

/// Default reminder presets for new tasks (time on due day) and events (offset).
class DefaultReminderSettingsSection extends StatefulWidget {
  const DefaultReminderSettingsSection({super.key});

  @override
  State<DefaultReminderSettingsSection> createState() =>
      _DefaultReminderSettingsSectionState();
}

class _DefaultReminderSettingsSectionState
    extends State<DefaultReminderSettingsSection> {
  TimeOfDay? _taskTime;
  int? _eventMinutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final NotificationPreferencesRepository prefs =
        context.read<NotificationPreferencesRepository>();
    final TimeOfDay taskTime = await prefs.getDefaultTaskReminderTime();
    final int eventMinutes = await prefs.getDefaultReminderMinutes();
    if (mounted) {
      setState(() {
        _taskTime = taskTime;
        _eventMinutes = eventMinutes;
      });
    }
  }

  Future<void> _pickTaskTime() async {
    final TimeOfDay? initial = _taskTime;
    if (initial == null) {
      return;
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) {
      return;
    }
    setState(() => _taskTime = picked);
    await context
        .read<NotificationPreferencesRepository>()
        .setDefaultTaskReminderTime(picked);
  }

  Future<void> _onEventMinutesChanged(int? minutes) async {
    if (minutes == null) {
      return;
    }
    setState(() => _eventMinutes = minutes);
    await context
        .read<NotificationPreferencesRepository>()
        .setDefaultReminderMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final TimeOfDay? taskTime = _taskTime;
    final int? eventMinutes = _eventMinutes;
    if (taskTime == null || eventMinutes == null) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final String taskTimeLabel = L10n.dateFormat('HH:mm').format(
      DateTime(2000, 1, 1, taskTime.hour, taskTime.minute),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'settings_default_task_reminder_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickTaskTime,
            icon: const Icon(Icons.schedule),
            label: Text(
              'settings_default_task_reminder_time'.tr(
                namedArgs: <String, String>{'time': taskTimeLabel},
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'settings_default_event_reminder_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ReminderPickerField(
            valueMinutes: eventMinutes,
            includeNone: false,
            onChanged: _onEventMinutesChanged,
          ),
        ],
      ),
    );
  }
}
