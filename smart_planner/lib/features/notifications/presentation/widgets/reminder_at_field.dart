import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';

/// Picks an absolute date/time when a task reminder should fire.
class ReminderAtField extends StatelessWidget {
  const ReminderAtField({
    required this.reminderAt,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final DateTime? reminderAt;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = reminderAt ?? now.add(const Duration(hours: 1));
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? now.subtract(const Duration(days: 1)),
      lastDate: lastDate ?? now.add(const Duration(days: 365 * 2)),
      locale: context.locale,
    );
    if (date == null || !context.mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return;
    }
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  String _format(BuildContext context, DateTime value) {
    return L10n.dateFormat('d MMM yyyy, HH:mm', context: context).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? at = reminderAt;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              at == null
                  ? 'reminder_pick_datetime'.tr()
                  : 'reminder_datetime_value'.tr(
                      namedArgs: <String, String>{
                        'datetime': _format(context, at),
                      },
                    ),
            ),
          ),
        ),
        if (at != null) ...<Widget>[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'reminder_clear'.tr(),
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear),
          ),
        ],
      ],
    );
  }
}
