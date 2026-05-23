import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/data/attachment_file_store.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/services/attachment_launcher_service.dart';
import 'package:smart_planner/features/todo_list/data/services/map_app_launcher_service.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_section_header.dart';

/// Attachments block in an expanded task tile.
class TaskAttachmentsSection extends StatelessWidget {
  const TaskAttachmentsSection({
    required this.attachments,
    required this.attachmentRepository,
    required this.onDeleteAttachment,
    required this.onToggleChecklistItem,
    required this.onAddAttachment,
    super.key,
  });

  final List<TaskAttachment> attachments;
  final TaskAttachmentRepository attachmentRepository;
  final void Function(Id attachmentId) onDeleteAttachment;
  final void Function(Id attachmentId, int itemLocalId) onToggleChecklistItem;
  final VoidCallback onAddAttachment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<TaskAttachment> checklists = attachments
        .where((TaskAttachment a) => a.type == TaskAttachmentType.checklist)
        .toList(growable: false);
    final List<TaskAttachment> otherAttachments = attachments
        .where((TaskAttachment a) => a.type != TaskAttachmentType.checklist)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TaskTileSectionHeader(
          icon: Icons.attach_file,
          title: 'Вложения',
          trailing: attachments.isEmpty ? null : '${attachments.length}',
          iconColor: colors.primary,
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Text(
            'Нет вложений',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else ...<Widget>[
          if (checklists.isNotEmpty) ...<Widget>[
            TaskTileSectionHeader(
              icon: Icons.fact_check,
              title: 'Чеклист',
              trailing: _checklistSectionTrailing(checklists),
              iconColor: colors.secondary,
            ),
            const SizedBox(height: 8),
            ...checklists.map(
              (TaskAttachment attachment) => _AttachmentTile(
                attachment: attachment,
                attachmentRepository: attachmentRepository,
                onDelete: () => onDeleteAttachment(attachment.id),
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
                title: 'Другие вложения',
                trailing: '${otherAttachments.length}',
                iconColor: colors.onSurfaceVariant,
              ),
            if (checklists.isNotEmpty) const SizedBox(height: 8),
            ...otherAttachments.map(
              (TaskAttachment attachment) => _AttachmentTile(
                attachment: attachment,
                attachmentRepository: attachmentRepository,
                onDelete: () => onDeleteAttachment(attachment.id),
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
          label: const Text('Добавить вложение'),
        ),
      ],
    );
  }

  static String? _checklistSectionTrailing(List<TaskAttachment> checklists) {
    if (checklists.isEmpty) {
      return null;
    }
    final ChecklistProgress progress = TaskAttachmentChecklist.progress(
      TaskAttachmentCodec.checklist(checklists.first),
    );
    if (!progress.hasItems) {
      return null;
    }
    return '${progress.completed}/${progress.total}';
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.attachmentRepository,
    required this.onDelete,
    required this.onToggleNoteItem,
  });

  final TaskAttachment attachment;
  final TaskAttachmentRepository attachmentRepository;
  final VoidCallback onDelete;
  final void Function(int localId) onToggleNoteItem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String title = TaskAttachmentCodec.summaryLabel(attachment);
    final bool urlInHeader = attachment.type == TaskAttachmentType.url;
    final Widget? headerTitle = urlInHeader
        ? _UrlHeaderLink(attachment: attachment)
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
            attachmentRepository: attachmentRepository,
            onToggleNoteItem: onToggleNoteItem,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, urlInHeader ? 4 : 8, 4, body == null ? 4 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(_iconForType(attachment.type), size: 20),
                const SizedBox(width: 8),
                Expanded(child: headerTitle!),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Удалить вложение',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
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
    };
  }
}

class _AttachmentBody extends StatelessWidget {
  const _AttachmentBody({
    required this.attachment,
    required this.attachmentRepository,
    required this.onToggleNoteItem,
  });

  final TaskAttachment attachment;
  final TaskAttachmentRepository attachmentRepository;
  final void Function(int localId) onToggleNoteItem;

  @override
  Widget build(BuildContext context) {
    return switch (attachment.type) {
      TaskAttachmentType.contact => _ContactBody(attachment: attachment),
      TaskAttachmentType.image => _ImageBody(
          attachment: attachment,
          fileStore: attachmentRepository.fileStore,
        ),
      TaskAttachmentType.url => const SizedBox.shrink(),
      TaskAttachmentType.location => _LocationBody(attachment: attachment),
      TaskAttachmentType.note => _NoteBody(attachment: attachment),
      TaskAttachmentType.checklist => _ChecklistBody(
          attachment: attachment,
          onToggleItem: onToggleNoteItem,
        ),
    };
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.attachment});

  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final ContactAttachmentPayload contact =
        TaskAttachmentCodec.contact(attachment);
    final String? phone = contact.primaryPhone.isNotEmpty
        ? contact.primaryPhone
        : null;
    final String? email =
        contact.emails.isNotEmpty ? contact.emails.first : null;

    final TextStyle? linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (phone != null)
          InkWell(
            onTap: () => _launchOrSnack(
              context,
              AttachmentLauncherService.dialPhone(phone),
              'Не удалось открыть звонок',
            ),
            child: Text(phone, style: linkStyle),
          ),
        if (phone != null)
          InkWell(
            onTap: () => _launchOrSnack(
              context,
              AttachmentLauncherService.sendSms(phone),
              'Не удалось открыть SMS',
            ),
            child: Text('SMS', style: linkStyle),
          ),
        if (email != null)
          InkWell(
            onTap: () => _launchOrSnack(
              context,
              AttachmentLauncherService.sendEmail(email),
              'Не удалось открыть почту',
            ),
            child: Text(email, style: linkStyle),
          ),
      ],
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.attachment,
    required this.fileStore,
  });

  final TaskAttachment attachment;
  final AttachmentFileStore fileStore;

  @override
  Widget build(BuildContext context) {
    final ImageAttachmentPayload payload = TaskAttachmentCodec.image(attachment);

    return FutureBuilder<File>(
      future: fileStore.resolveFile(payload.relativePath),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (!snapshot.hasData || !snapshot.data!.existsSync()) {
          return const Text('Файл изображения не найден');
        }
        final File file = snapshot.data!;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ImageViewerPage(file: file),
              ),
            ),
            child: Image.file(
              file,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({required this.file});

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

class _UrlHeaderLink extends StatelessWidget {
  const _UrlHeaderLink({required this.attachment});

  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final UrlAttachmentPayload payload = TaskAttachmentCodec.url(attachment);
    final String linkText = urlAttachmentLinkLabel(payload);
    final TextStyle linkStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        );

    return InkWell(
      onTap: () => _launchOrSnack(
        context,
        AttachmentLauncherService.openUrl(payload.url),
        'Не удалось открыть ссылку',
      ),
      child: Text(
        linkText,
        style: linkStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LocationBody extends StatelessWidget {
  const _LocationBody({required this.attachment});

  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final LocationAttachmentPayload payload =
        TaskAttachmentCodec.location(attachment);
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
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => _openInMaps(context, payload),
            icon: const Icon(Icons.navigation_outlined, size: 18),
            label: const Text('Открыть в картах'),
          ),
        ),
      ],
    );
  }

  static Future<void> _openInMaps(
    BuildContext context,
    LocationAttachmentPayload payload,
  ) async {
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
        'Не удалось открыть карты',
      );
    }
  }
}

class _NoteBody extends StatelessWidget {
  const _NoteBody({required this.attachment});

  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final NoteAttachmentPayload note = TaskAttachmentCodec.note(attachment);
    if (note.body.trim().isEmpty) {
      return Text(
        'Пустая заметка',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
      );
    }
    final String? title = note.title?.trim();
    if (title != null && title.isNotEmpty) {
      return Text(note.body, style: Theme.of(context).textTheme.bodyMedium);
    }
    return Text(note.body, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _ChecklistBody extends StatelessWidget {
  const _ChecklistBody({
    required this.attachment,
    required this.onToggleItem,
  });

  final TaskAttachment attachment;
  final void Function(int localId) onToggleItem;

  @override
  Widget build(BuildContext context) {
    final ChecklistAttachmentPayload checklist =
        TaskAttachmentCodec.checklist(attachment);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    if (checklist.items.isEmpty) {
      return Text(
        'Нет пунктов',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: checklist.items.map(
        (ChecklistItemPayload item) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.isCompleted,
                onChanged: (_) => onToggleItem(item.localId),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Expanded(
              child: Text(
                item.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration:
                      item.isCompleted ? TextDecoration.lineThrough : null,
                  color: item.isCompleted
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ).toList(),
    );
  }
}

Future<void> _launchOrSnack(
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
