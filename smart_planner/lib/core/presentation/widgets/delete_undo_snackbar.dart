import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows a delete confirmation snackbar with undo for [undoDuration].
void showDeleteUndoSnackBar(
  BuildContext context, {
  required String messageKey,
  required VoidCallback onUndo,
  Duration undoDuration = const Duration(seconds: 10),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(messageKey.tr()),
      duration: undoDuration,
      action: SnackBarAction(
        label: 'snackbar_undo'.tr(),
        onPressed: onUndo,
      ),
    ),
  );
}
