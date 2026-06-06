import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/presentation/widgets/sliding_completion_list.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// Inline checklist on task/event detail with slide animation on toggle.
class ChecklistAttachmentBody extends StatelessWidget {
  const ChecklistAttachmentBody({
    required this.attachment,
    required this.onToggleItem,
    super.key,
  });

  final AttachmentRef attachment;
  final void Function(int localId) onToggleItem;

  static const double _checkboxLeadingWidth = 26;
  static const int _maxTextLines = 3;

  @override
  Widget build(BuildContext context) {
    final ChecklistAttachmentPayload checklist =
        TaskAttachmentCodec.checklistRef(attachment);
    final List<ChecklistItemPayload> items =
        TaskAttachmentChecklist.displayItems(checklist);
    final TextStyle textStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxTextWidth = _maxTextWidth(constraints.maxWidth);

        return SlidingCompletionList<ChecklistItemPayload>(
          items: items,
          idOf: (ChecklistItemPayload item) => item.localId,
          isCompleted: (ChecklistItemPayload item) => item.isCompleted,
          toggleItem: (ChecklistItemPayload item) => ChecklistItemPayload(
            localId: item.localId,
            text: item.text,
            isCompleted: !item.isCompleted,
          ),
          itemExtent: (ChecklistItemPayload item) =>
              completionCheckboxRowExtent(
            context: context,
            text: item.text,
            maxTextWidth: maxTextWidth,
            textStyle: textStyle,
            maxLines: _maxTextLines,
          ),
          moveCompletedToEnd: checklist.moveCompletedToEnd,
          onToggle: (ChecklistItemPayload item) => onToggleItem(item.localId),
          emptyBuilder: (BuildContext context) => Text(
            'attachment_no_checklist_items'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          itemBuilder: (
            BuildContext context,
            ChecklistItemPayload item, {
            required bool syncStyleWithSlide,
            required Animation<double>? styleProgress,
            required VoidCallback onToggle,
          }) {
            return _ChecklistItemRow(
              item: item,
              syncStyleWithSlide: syncStyleWithSlide,
              styleProgress: styleProgress,
              onToggle: onToggle,
              maxLines: _maxTextLines,
            );
          },
        );
      },
    );
  }

  static double _maxTextWidth(double constraintWidth) {
    if (constraintWidth.isFinite && constraintWidth > _checkboxLeadingWidth) {
      return constraintWidth - _checkboxLeadingWidth;
    }
    return 280;
  }
}

class _ChecklistItemRow extends StatelessWidget {
  const _ChecklistItemRow({
    required this.item,
    required this.onToggle,
    required this.maxLines,
    this.syncStyleWithSlide = false,
    this.styleProgress,
  });

  final ChecklistItemPayload item;
  final VoidCallback onToggle;
  final int maxLines;
  final bool syncStyleWithSlide;
  final Animation<double>? styleProgress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle baseStyle =
        theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle completedStyle = baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
      decorationColor: colors.onSurfaceVariant.withValues(alpha: 0.7),
      color: colors.onSurfaceVariant,
    );
    final TextStyle activeStyle = baseStyle.copyWith(
      color: colors.onSurface,
      decoration: TextDecoration.none,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.isCompleted,
                onChanged: (_) => onToggle(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: CompletionTextLabel(
              text: item.text,
              isCompleted: item.isCompleted,
              activeStyle: activeStyle,
              completedStyle: completedStyle,
              syncStyleWithSlide: syncStyleWithSlide,
              styleProgress: styleProgress,
              maxLines: maxLines,
            ),
          ),
        ],
      ),
    );
  }
}
