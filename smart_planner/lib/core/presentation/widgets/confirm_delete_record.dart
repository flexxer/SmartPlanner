import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows the standard delete confirmation dialog used by create/edit form sheets.
Future<bool> confirmDeleteRecord(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      final ColorScheme colors = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text('delete_dialog_title'.tr()),
        content: Text('delete_dialog_body'.tr()),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            child: Text('common_delete'.tr()),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
