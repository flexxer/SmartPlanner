import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/notifications/domain/reminder_labels.dart';
import 'package:smart_planner/features/notifications/domain/reminder_options.dart';

/// Dropdown for per-item reminder offset ([null] = none).
class ReminderPickerField extends StatelessWidget {
  const ReminderPickerField({
    required this.valueMinutes,
    required this.onChanged,
    this.enabled = true,
    this.includeNone = true,
    super.key,
  });

  /// `null` = no reminder; otherwise minutes before anchor time.
  final int? valueMinutes;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  /// When false, only [ReminderOptions.selectableMinutes] are shown (for app default).
  final bool includeNone;

  @override
  Widget build(BuildContext context) {
    final int dropdownValue = valueMinutes ?? ReminderOptions.noneSentinel;

    return DropdownButtonFormField<int>(
      key: ValueKey<int>(dropdownValue),
      initialValue: dropdownValue,
      decoration: InputDecoration(
        labelText: 'field_reminder'.tr(),
        border: const OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<int>>[
        if (includeNone)
          DropdownMenuItem<int>(
            value: ReminderOptions.noneSentinel,
            child: Text('reminder_none'.tr()),
          ),
        ...ReminderOptions.selectableMinutes.map(
          (int minutes) => DropdownMenuItem<int>(
            value: minutes,
            child: Text(ReminderLabels.labelForMinutes(minutes)),
          ),
        ),
      ],
      onChanged: enabled
          ? (int? picked) {
              if (picked == null) {
                return;
              }
              if (picked == ReminderOptions.noneSentinel) {
                onChanged(null);
              } else {
                onChanged(picked);
              }
            }
          : null,
    );
  }

}
