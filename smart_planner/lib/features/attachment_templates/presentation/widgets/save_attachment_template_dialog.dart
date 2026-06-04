import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks for a name when saving an attachment as a reusable template.
Future<String?> showSaveAttachmentTemplateDialog(
  BuildContext context, {
  required String initialTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController controller =
          TextEditingController(text: initialTitle);
      return AlertDialog(
        title: Text('attachment_template_save_from_attachment'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'attachment_template_field_title'.tr(),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (String value) {
            final String trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              Navigator.pop(context, trimmed);
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final String trimmed = controller.text.trim();
              if (trimmed.isEmpty) {
                return;
              }
              Navigator.pop(context, trimmed);
            },
            child: Text('common_save'.tr()),
          ),
        ],
      );
    },
  );
}
