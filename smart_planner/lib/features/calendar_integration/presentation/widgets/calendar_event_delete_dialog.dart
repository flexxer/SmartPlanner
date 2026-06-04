import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// User choice when deleting a recurring calendar event.
enum CalendarEventDeleteScope {
  thisInstance,
  entireSeries,
}

/// Asks whether to delete one occurrence or the full series.
Future<CalendarEventDeleteScope?> showCalendarEventDeleteDialog(
  BuildContext context,
) {
  return showDialog<CalendarEventDeleteScope>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text('event_delete_recurring_title'.tr()),
      content: Text('event_delete_recurring_body'.tr()),
      actions: <Widget>[
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(CalendarEventDeleteScope.thisInstance),
          child: Text('event_delete_this_instance'.tr()),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(CalendarEventDeleteScope.entireSeries),
          child: Text('event_delete_entire_series'.tr()),
        ),
      ],
    ),
  );
}
