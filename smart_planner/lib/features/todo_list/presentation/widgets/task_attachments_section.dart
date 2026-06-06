import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/attachment_templates/data/repositories/attachment_template_repository.dart';
import 'package:smart_planner/features/attachment_templates/domain/attachment_template_factory.dart';
import 'package:smart_planner/features/attachment_templates/presentation/widgets/save_attachment_template_dialog.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/attachment_action_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/checklist_attachment_body.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_section_header.dart';

/// Attachments block on task or event detail screens.
class TaskAttachmentsSection extends StatelessWidget {
  const TaskAttachmentsSection({
    required this.attachments,
    required this.fileStore,
    required this.onEditAttachment,
    required this.onDeleteAttachment,
    required this.onToggleChecklistItem,
    required this.onAddAttachment,
    this.onReorder,
    super.key,
  });

  final List<AttachmentRef> attachments;
  final AttachmentFileStore fileStore;
  final void Function(AttachmentRef attachment) onEditAttachment;
  final void Function(AttachmentRef attachment) onDeleteAttachment;
  final void Function(Id attachmentId, int itemLocalId) onToggleChecklistItem;
  final VoidCallback onAddAttachment;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<AttachmentRef> checklists = attachments
        .where((AttachmentRef a) => a.type == TaskAttachmentType.checklist)
        .toList(growable: false);
    final List<AttachmentRef> otherAttachments = attachments
        .where((AttachmentRef a) => a.type != TaskAttachmentType.checklist)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TaskTileSectionHeader(
          icon: Icons.attach_file,
          title: 'attachments_title'.tr(),
          trailing: attachments.isEmpty ? null : '${attachments.length}',
          iconColor: colors.primary,
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Text(
            'attachments_empty'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (onReorder != null) ...<Widget>[
          Text(
            'attachments_reorder_hint'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: attachments.length,
            onReorder: onReorder!,
            itemBuilder: (BuildContext context, int index) {
              final AttachmentRef attachment = attachments[index];
              return _ReorderableAttachmentRow(
                key: ValueKey<int>(attachment.id),
                index: index,
                attachment: attachment,
                fileStore: fileStore,
                onEditAttachment: () => onEditAttachment(attachment),
                onDeleteAttachment: () => onDeleteAttachment(attachment),
                onToggleNoteItem: (int localId) =>
                    onToggleChecklistItem(attachment.id, localId),
              );
            },
          ),
        ] else ...<Widget>[
          if (checklists.isNotEmpty) ...<Widget>[
            TaskTileSectionHeader(
              icon: Icons.fact_check,
              title: 'attachments_checklist'.tr(),
              trailing: _checklistSectionTrailing(checklists),
              iconColor: colors.secondary,
            ),
            const SizedBox(height: 8),
            ...checklists.map(
              (AttachmentRef attachment) => _AttachmentTile(
                attachment: attachment,
                fileStore: fileStore,
                onEditAttachment: () => onEditAttachment(attachment),
                onDeleteAttachment: () => onDeleteAttachment(attachment),
                onToggleNoteItem: (int localId) =>
                    onToggleChecklistItem(attachment.id, localId),
              ),
            ),
          ],
          if (checklists.isNotEmpty && otherAttachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 8),
          ],
          if (otherAttachments.isNotEmpty) ...<Widget>[
            if (checklists.isNotEmpty)
              TaskTileSectionHeader(
                icon: Icons.layers_outlined,
                title: 'attachments_other'.tr(),
                trailing: '${otherAttachments.length}',
                iconColor: colors.onSurfaceVariant,
              ),
            if (checklists.isNotEmpty) const SizedBox(height: 8),
            ...otherAttachments.map(
              (AttachmentRef attachment) => _AttachmentTile(
                attachment: attachment,
                fileStore: fileStore,
                onEditAttachment: () => onEditAttachment(attachment),
                onDeleteAttachment: () => onDeleteAttachment(attachment),
                onToggleNoteItem: (int localId) =>
                    onToggleChecklistItem(attachment.id, localId),
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddAttachment,
          icon: const Icon(Icons.attach_file, size: 18),
          label: Text('attachments_add'.tr()),
        ),
      ],
    );
  }

  static String? _checklistSectionTrailing(List<AttachmentRef> checklists) {
    if (checklists.isEmpty) {
      return null;
    }
    final ChecklistProgress progress = TaskAttachmentChecklist.progress(
      TaskAttachmentCodec.checklistRef(checklists.first),
    );
    if (!progress.hasItems) {
      return null;
    }
    return '${progress.completed}/${progress.total}';
  }
}

class _ReorderableAttachmentRow extends StatelessWidget {
  const _ReorderableAttachmentRow({
    required super.key,
    required this.index,
    required this.attachment,
    required this.fileStore,
    required this.onEditAttachment,
    required this.onDeleteAttachment,
    required this.onToggleNoteItem,
  });

  final int index;
  final AttachmentRef attachment;
  final AttachmentFileStore fileStore;
  final VoidCallback onEditAttachment;
  final VoidCallback onDeleteAttachment;
  final void Function(int localId) onToggleNoteItem;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 4, 8),
              child: Icon(
                Icons.drag_handle,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _AttachmentTile(
              attachment: attachment,
              fileStore: fileStore,
              onEditAttachment: onEditAttachment,
              onDeleteAttachment: onDeleteAttachment,
              onToggleNoteItem: onToggleNoteItem,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.fileStore,
    required this.onEditAttachment,
    required this.onDeleteAttachment,
    required this.onToggleNoteItem,
  });

  final AttachmentRef attachment;
  final AttachmentFileStore fileStore;
  final VoidCallback onEditAttachment;
  final VoidCallback onDeleteAttachment;
  final void Function(int localId) onToggleNoteItem;

  Future<void> _saveAsTemplate(BuildContext context) async {
    final String initialTitle = TaskAttachmentCodec.summaryLabelRef(attachment);
    final String? title = await showSaveAttachmentTemplateDialog(
      context,
      initialTitle: initialTitle,
    );
    if (title == null || !context.mounted) {
      return;
    }
    final AttachmentTemplateRepository repository =
        context.read<AttachmentTemplateRepository>();
    final int sortOrder = await repository.nextSortOrder();
    await repository.save(
      AttachmentTemplateFactory.fromAttachmentRef(
        attachment,
        title: title,
        sortOrder: sortOrder,
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('attachment_template_saved'.tr())),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final bool canTemplate =
        AttachmentTemplateFactory.canSaveAsTemplate(attachment.type);
    await showAttachmentActionSheetRef(
      context,
      attachment: attachment,
      fileStore: fileStore,
      onEdit: onEditAttachment,
      onDelete: onDeleteAttachment,
      onSaveAsTemplate:
          canTemplate ? () => _saveAsTemplate(context) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String title = TaskAttachmentCodec.summaryLabelRef(attachment);
    final bool urlInHeader = attachment.type == TaskAttachmentType.url;
    final Widget headerTitle = urlInHeader
        ? _UrlHeaderTitle(attachment: attachment)
        : Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

    final Widget? body = urlInHeader
        ? null
        : _AttachmentBody(
            attachment: attachment,
            fileStore: fileStore,
            onToggleNoteItem: onToggleNoteItem,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showActions(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            urlInHeader ? 8 : 8,
            12,
            body == null ? 8 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(_iconForType(attachment.type), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: headerTitle),
                  Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              if (body != null) ...<Widget>[
                const SizedBox(height: 4),
                body,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.contact => Icons.contact_phone_outlined,
      TaskAttachmentType.image => Icons.image_outlined,
      TaskAttachmentType.url => Icons.link,
      TaskAttachmentType.location => Icons.place_outlined,
      TaskAttachmentType.note => Icons.sticky_note_2_outlined,
      TaskAttachmentType.checklist => Icons.fact_check,
      TaskAttachmentType.file => Icons.insert_drive_file_outlined,
    };
  }
}

class _AttachmentBody extends StatelessWidget {
  const _AttachmentBody({
    required this.attachment,
    required this.fileStore,
    required this.onToggleNoteItem,
  });

  final AttachmentRef attachment;
  final AttachmentFileStore fileStore;
  final void Function(int localId) onToggleNoteItem;

  @override
  Widget build(BuildContext context) {
    return switch (attachment.type) {
      TaskAttachmentType.contact => _ContactBody(attachment: attachment),
      TaskAttachmentType.image => _ImageBody(
          attachment: attachment,
          fileStore: fileStore,
        ),
      TaskAttachmentType.file => _FileBody(attachment: attachment),
      TaskAttachmentType.url => const SizedBox.shrink(),
      TaskAttachmentType.location => _LocationBody(attachment: attachment),
      TaskAttachmentType.note => _NoteBody(attachment: attachment),
      TaskAttachmentType.checklist => ChecklistAttachmentBody(
          attachment: attachment,
          onToggleItem: onToggleNoteItem,
        ),
    };
  }
}

class _FileBody extends StatelessWidget {
  const _FileBody({required this.attachment});

  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context) {
    final FileAttachmentPayload payload =
        TaskAttachmentCodec.fileRef(attachment);
    return Text(
      payload.fileName,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.attachment});

  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context) {
    final ContactAttachmentPayload contact =
        TaskAttachmentCodec.contactRef(attachment);
    final String? phone = contact.primaryPhone.isNotEmpty
        ? contact.primaryPhone
        : null;
    final String? email =
        contact.emails.isNotEmpty ? contact.emails.first : null;

    final TextStyle? linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (phone != null) Text(phone, style: linkStyle),
        if (phone != null)
          Text('SMS', style: linkStyle?.copyWith(fontSize: 12)),
        if (email != null) Text(email, style: linkStyle),
      ],
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.attachment,
    required this.fileStore,
  });

  final AttachmentRef attachment;
  final AttachmentFileStore fileStore;

  @override
  Widget build(BuildContext context) {
    final ImageAttachmentPayload payload =
        TaskAttachmentCodec.imageRef(attachment);

    return FutureBuilder<File>(
      future: fileStore.resolveFile(payload.relativePath),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (!snapshot.hasData || !snapshot.data!.existsSync()) {
          return Text('attachment_image_missing'.tr());
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            snapshot.data!,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class _UrlHeaderTitle extends StatelessWidget {
  const _UrlHeaderTitle({required this.attachment});

  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context) {
    final UrlAttachmentPayload payload = TaskAttachmentCodec.urlRef(attachment);
    final String linkText = urlAttachmentLinkLabel(payload);
    final TextStyle linkStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        );

    return Text(
      linkText,
      style: linkStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _LocationBody extends StatelessWidget {
  const _LocationBody({required this.attachment});

  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final LocationAttachmentPayload payload =
        TaskAttachmentCodec.locationRef(attachment);
    final String placeTitle = TaskAttachmentCodec.locationDisplayTitle(
      payload,
      attachmentLabel: attachment.label,
    );
    final String coords =
        '${payload.latitude.toStringAsFixed(5)}, ${payload.longitude.toStringAsFixed(5)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          placeTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          coords,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NoteBody extends StatelessWidget {
  const _NoteBody({required this.attachment});

  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context) {
    final NoteAttachmentPayload note = TaskAttachmentCodec.noteRef(attachment);
    if (note.body.trim().isEmpty) {
      return Text(
        'attachment_empty_note'.tr(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
      );
    }
    return Text(note.body, style: Theme.of(context).textTheme.bodyMedium);
  }
}

/// Count of non-checklist attachments for the collapsed tile badge.
String? nonChecklistAttachmentCountBadgeLabel(
  List<TaskAttachment> attachments,
) {
  final int count = attachments
      .where((TaskAttachment a) => a.type != TaskAttachmentType.checklist)
      .length;
  if (count == 0) {
    return null;
  }
  return '$count';
}

/// Progress label for the first checklist attachment, e.g. "2/5".
String? checklistAttachmentProgressBadgeLabel(
  List<TaskAttachment> attachments,
) {
  for (final TaskAttachment attachment in attachments) {
    if (attachment.type == TaskAttachmentType.checklist) {
      final ChecklistProgress progress = TaskAttachmentChecklist.progress(
        TaskAttachmentCodec.checklist(attachment),
      );
      if (progress.hasItems) {
        return '${progress.completed}/${progress.total}';
      }
    }
  }
  return null;
}
