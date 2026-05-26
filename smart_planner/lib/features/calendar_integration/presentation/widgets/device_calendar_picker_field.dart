import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';

/// Tappable field that opens a list sheet to pick a [DeviceCalendarInfo].
///
/// Reliable inside modal bottom sheets (unlike [DropdownButtonFormField]).
class DeviceCalendarPickerField extends StatelessWidget {
  const DeviceCalendarPickerField({
    required this.calendars,
    required this.selectedCalendarId,
    required this.onCalendarSelected,
    this.hintText,
    super.key,
  });

  final List<DeviceCalendarInfo> calendars;
  final String? selectedCalendarId;
  final ValueChanged<DeviceCalendarInfo> onCalendarSelected;
  final String? hintText;

  DeviceCalendarInfo? get _selected {
    final String? id = selectedCalendarId;
    if (id == null) {
      return null;
    }
    for (final DeviceCalendarInfo calendar in calendars) {
      if (calendar.id == id) {
        return calendar;
      }
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (calendars.isEmpty) {
      return;
    }

    final DeviceCalendarInfo? picked = await showModalBottomSheet<DeviceCalendarInfo>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'common_calendar'.tr(),
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: calendars.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final DeviceCalendarInfo calendar = calendars[index];
                    final bool isSelected = calendar.id == selectedCalendarId;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(_colorArgb(calendar.colorValue)),
                      ),
                      title: Text(calendar.name),
                      subtitle: calendar.accountName != null
                          ? Text(
                              calendar.accountName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(sheetContext).colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(calendar),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      onCalendarSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DeviceCalendarInfo? selected = _selected;
    final String effectiveHint =
        hintText ?? 'event_form_select_calendar_hint'.tr();

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'common_calendar'.tr(),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Row(
            children: <Widget>[
              if (selected != null)
                CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(_colorArgb(selected.colorValue)),
                ),
              if (selected != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected?.name ?? effectiveHint,
                  style: selected == null
                      ? theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        )
                      : theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _colorArgb(int value) {
    if (value > 0xFFFFFF) {
      return value;
    }
    return 0xFF000000 | value;
  }
}
