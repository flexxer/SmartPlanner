import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/attachment_default_action.dart';

enum _AttachmentMenuAction {
  open,
  edit,
  delete,
}

/// Bottom sheet with open / edit / delete options for an attachment.
Future<void> showAttachmentActionSheet(
  BuildContext context, {
  required TaskAttachment attachment,
  required TaskAttachmentRepository attachmentRepository,
  required VoidCallback onEdit,
  required void Function(TaskAttachment attachment) onDelete,
}) async {
  final _AttachmentMenuAction? action = await showModalBottomSheet<_AttachmentMenuAction>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final ColorScheme colors = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'attachment_sheet_title'.tr(),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_outlined),
              title: Text('attachment_open_view'.tr()),
              onTap: () => Navigator.of(sheetContext).pop(
                _AttachmentMenuAction.open,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('attachment_edit'.tr()),
              onTap: () => Navigator.of(sheetContext).pop(
                _AttachmentMenuAction.edit,
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(
                'attachment_delete'.tr(),
                style: TextStyle(color: colors.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop(
                _AttachmentMenuAction.delete,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (!context.mounted || action == null) {
    return;
  }

  switch (action) {
    case _AttachmentMenuAction.open:
      await AttachmentDefaultAction.open(
        context,
        attachment: attachment,
        fileStore: attachmentRepository.fileStore,
      );
    case _AttachmentMenuAction.edit:
      onEdit();
    case _AttachmentMenuAction.delete:
      onDelete(attachment);
  }
}
