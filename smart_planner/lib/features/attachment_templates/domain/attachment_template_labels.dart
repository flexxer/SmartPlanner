import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// User-visible labels for [AttachmentTemplate] rows.
class AttachmentTemplateLabels {
  AttachmentTemplateLabels._();

  static String displayTitle(AttachmentTemplate template) {
    if (template.title.startsWith('attachment_template_')) {
      return template.title.tr();
    }
    return template.title;
  }

  static String copySuffix() => 'attachment_template_copy_suffix'.tr();

  static String typeLabel(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.contact => 'attachment_type_contact'.tr(),
      TaskAttachmentType.image => 'attachment_type_photo'.tr(),
      TaskAttachmentType.file => 'attachment_type_file'.tr(),
      TaskAttachmentType.url => 'attachment_type_url'.tr(),
      TaskAttachmentType.location => 'attachment_type_location'.tr(),
      TaskAttachmentType.note => 'attachment_type_note'.tr(),
      TaskAttachmentType.checklist => 'attachment_type_checklist'.tr(),
    };
  }

  static IconData iconFor(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.contact => Icons.contact_phone_outlined,
      TaskAttachmentType.image => Icons.image_outlined,
      TaskAttachmentType.file => Icons.insert_drive_file_outlined,
      TaskAttachmentType.url => Icons.link,
      TaskAttachmentType.location => Icons.place_outlined,
      TaskAttachmentType.note => Icons.sticky_note_2_outlined,
      TaskAttachmentType.checklist => Icons.checklist,
    };
  }
}
