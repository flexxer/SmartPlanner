import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/data/services/attachment_launcher_service.dart';
import 'package:smart_planner/features/todo_list/data/services/map_app_launcher_service.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// Default "open / view" behavior for a [TaskAttachment] (previously on direct tap).
class AttachmentDefaultAction {
  AttachmentDefaultAction._();

  static Future<void> open(
    BuildContext context, {
    required TaskAttachment attachment,
    required AttachmentFileStore fileStore,
  }) async {
    switch (attachment.type) {
      case TaskAttachmentType.contact:
        await _openContact(context, attachment);
      case TaskAttachmentType.image:
        await _openImage(context, attachment, fileStore);
      case TaskAttachmentType.url:
        await _openUrl(context, attachment);
      case TaskAttachmentType.location:
        await _openLocation(context, attachment);
      case TaskAttachmentType.note:
        await _openNote(context, attachment);
      case TaskAttachmentType.checklist:
        break;
    }
  }

  static Future<void> _openContact(
    BuildContext context,
    TaskAttachment attachment,
  ) async {
    final ContactAttachmentPayload contact =
        TaskAttachmentCodec.contact(attachment);
    final String? phone = contact.primaryPhone.isNotEmpty
        ? contact.primaryPhone
        : null;
    final String? email =
        contact.emails.isNotEmpty ? contact.emails.first : null;

    if (phone != null) {
      await _launchOrSnack(
        context,
        AttachmentLauncherService.dialPhone(phone),
        'attachment_call_failed'.tr(),
      );
      return;
    }
    if (email != null) {
      await _launchOrSnack(
        context,
        AttachmentLauncherService.sendEmail(email),
        'attachment_email_failed'.tr(),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('attachment_no_contact_methods'.tr())),
    );
  }

  static Future<void> _openImage(
    BuildContext context,
    TaskAttachment attachment,
    AttachmentFileStore fileStore,
  ) async {
    final ImageAttachmentPayload payload = TaskAttachmentCodec.image(attachment);
    final File file = await fileStore.resolveFile(payload.relativePath);
    if (!context.mounted) {
      return;
    }
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('attachment_image_missing'.tr())),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AttachmentImageViewerPage(file: file),
      ),
    );
  }

  static Future<void> _openUrl(
    BuildContext context,
    TaskAttachment attachment,
  ) async {
    final UrlAttachmentPayload payload = TaskAttachmentCodec.url(attachment);
    await _launchOrSnack(
      context,
      AttachmentLauncherService.openUrl(payload.url),
      'attachment_url_failed'.tr(),
    );
  }

  static Future<void> _openLocation(
    BuildContext context,
    TaskAttachment attachment,
  ) async {
    final LocationAttachmentPayload payload =
        TaskAttachmentCodec.location(attachment);
    final bool ok = await MapAppLauncherService.showAtCoordinate(
      context: context,
      latitude: payload.latitude,
      longitude: payload.longitude,
    );
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      await _launchOrSnack(
        context,
        AttachmentLauncherService.openMaps(
          latitude: payload.latitude,
          longitude: payload.longitude,
        ),
        'attachment_maps_failed'.tr(),
      );
    }
  }

  static Future<void> _openNote(
    BuildContext context,
    TaskAttachment attachment,
  ) async {
    final NoteAttachmentPayload note = TaskAttachmentCodec.note(attachment);
    final String body = note.body.trim();
    if (body.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('attachment_note_empty_snackbar'.tr())),
      );
      return;
    }
    final String? title = note.title?.trim();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            title != null && title.isNotEmpty
                ? title
                : 'attachment_note_dialog_title'.tr(),
          ),
          content: SingleChildScrollView(
            child: Text(body),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('common_close'.tr()),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _launchOrSnack(
    BuildContext context,
    Future<bool> launchFuture,
    String errorMessage,
  ) async {
    final bool ok = await launchFuture;
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}

class _AttachmentImageViewerPage extends StatelessWidget {
  const _AttachmentImageViewerPage({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }
}
