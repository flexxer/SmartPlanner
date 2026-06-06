import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_checklist.dart';

/// Fixed row height — enables [ReorderableListView] [itemExtent] fast path.
const double kChecklistEditorRowHeight = 48;

/// Max height of the reorderable list (scrolls inside, not the parent sheet).
const double kChecklistEditorListMaxHeight = 280;

/// Checklist editor with local state (no parent rebuilds while typing or dragging).
class ChecklistEditorSection extends StatefulWidget {
  const ChecklistEditorSection({
    required this.titleController,
    required this.initialItems,
    this.initialMoveCompletedToEnd = true,
    super.key,
  });

  final TextEditingController titleController;
  final List<ChecklistItemPayload> initialItems;
  final bool initialMoveCompletedToEnd;

  @override
  ChecklistEditorSectionState createState() => ChecklistEditorSectionState();
}

class ChecklistEditorSectionState extends State<ChecklistEditorSection> {
  late final ValueNotifier<List<ChecklistItemPayload>> _itemsNotifier;
  final TextEditingController _newItemController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  int? _editingLocalId;
  late bool _moveCompletedToEnd;

  bool get moveCompletedToEnd => _moveCompletedToEnd;

  @override
  void initState() {
    super.initState();
    _moveCompletedToEnd = widget.initialMoveCompletedToEnd;
    _itemsNotifier = ValueNotifier<List<ChecklistItemPayload>>(
      List<ChecklistItemPayload>.from(widget.initialItems),
    );
    _editFocusNode.addListener(_onEditFocusChanged);
  }

  @override
  void dispose() {
    _editFocusNode.removeListener(_onEditFocusChanged);
    _itemsNotifier.dispose();
    _newItemController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _onEditFocusChanged() {
    if (!_editFocusNode.hasFocus) {
      _commitEditing();
    }
  }

  List<ChecklistItemPayload> get _items => _itemsNotifier.value;

  void _setItems(List<ChecklistItemPayload> items) {
    _itemsNotifier.value = items;
  }

  /// Items to persist (includes pending new-line text).
  List<ChecklistItemPayload> collectItems() {
    _commitEditing();
    final List<ChecklistItemPayload> result =
        List<ChecklistItemPayload>.from(_items);
    final String pending = _newItemController.text.trim();
    if (pending.isNotEmpty) {
      result.add(
        ChecklistItemPayload(
          localId: TaskAttachmentChecklist.nextItemLocalId(result),
          text: pending,
        ),
      );
    }
    return result;
  }

  void _commitEditing() {
    final int? editingId = _editingLocalId;
    if (editingId == null) {
      return;
    }
    final String text = _editController.text.trim();
    final List<ChecklistItemPayload> items =
        List<ChecklistItemPayload>.from(_items);
    final int index = items.indexWhere(
      (ChecklistItemPayload i) => i.localId == editingId,
    );
    if (index >= 0) {
      if (text.isEmpty) {
        items.removeAt(index);
      } else {
        final ChecklistItemPayload current = items[index];
        items[index] = ChecklistItemPayload(
          localId: current.localId,
          text: text,
          isCompleted: current.isCompleted,
        );
      }
      _setItems(items);
    }
    if (_editingLocalId != null) {
      setState(() {
        _editingLocalId = null;
        _editController.clear();
      });
    }
  }

  void _startEditing(ChecklistItemPayload item) {
    _commitEditing();
    setState(() {
      _editingLocalId = item.localId;
      _editController.text = item.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _removeItem(int localId) {
    _commitEditing();
    final List<ChecklistItemPayload> items =
        List<ChecklistItemPayload>.from(_items);
    items.removeWhere((ChecklistItemPayload i) => i.localId == localId);
    _setItems(items);
    if (_editingLocalId == localId) {
      setState(() {
        _editingLocalId = null;
        _editController.clear();
      });
    }
  }

  void _addItem(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _commitEditing();
    final List<ChecklistItemPayload> items =
        List<ChecklistItemPayload>.from(_items);
    items.add(
      ChecklistItemPayload(
        localId: TaskAttachmentChecklist.nextItemLocalId(items),
        text: trimmed,
      ),
    );
    _setItems(items);
    _newItemController.clear();
  }

  void _reorderItem(int oldIndex, int newIndex) {
    _commitEditing();
    final List<ChecklistItemPayload> items =
        List<ChecklistItemPayload>.from(_items);
    final ChecklistItemPayload item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    _setItems(items);
  }

  static double _listViewportHeight(int itemCount) {
    if (itemCount == 0) {
      return 0;
    }
    final double contentHeight = itemCount * kChecklistEditorRowHeight;
    return contentHeight.clamp(
      kChecklistEditorRowHeight,
      kChecklistEditorListMaxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: widget.titleController,
          decoration: InputDecoration(
            labelText: 'attachment_field_name'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'attachment_settings'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _moveCompletedToEnd,
          onChanged: (bool? value) {
            setState(() => _moveCompletedToEnd = value ?? true);
          },
          title: Text('attachment_checklist_move_completed_to_end'.tr()),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<ChecklistItemPayload>>(
          valueListenable: _itemsNotifier,
          builder: (
            BuildContext context,
            List<ChecklistItemPayload> items,
            Widget? child,
          ) {
            if (items.isEmpty && _editingLocalId == null) {
              return Text(
                'attachment_checklist_empty_hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: _listViewportHeight(items.length),
              child: _ChecklistReorderableList(
                items: items,
                editingLocalId: _editingLocalId,
                editController: _editController,
                editFocusNode: _editFocusNode,
                onStartEdit: _startEditing,
                onCommitEdit: _commitEditing,
                onRemove: _removeItem,
                onReorderItem: _reorderItem,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _newItemController,
                decoration: InputDecoration(
                  hintText: 'attachment_checklist_add_bottom_hint'.tr(),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _addItem,
              ),
            ),
            IconButton(
              onPressed: () => _addItem(_newItemController.text),
              icon: const Icon(Icons.add),
              tooltip: 'attachment_add_item_tooltip'.tr(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reorderable checklist rows in a bounded viewport (not [shrinkWrap]).
class _ChecklistReorderableList extends StatelessWidget {
  const _ChecklistReorderableList({
    required this.items,
    required this.editingLocalId,
    required this.editController,
    required this.editFocusNode,
    required this.onStartEdit,
    required this.onCommitEdit,
    required this.onRemove,
    required this.onReorderItem,
  });

  final List<ChecklistItemPayload> items;
  final int? editingLocalId;
  final TextEditingController editController;
  final FocusNode editFocusNode;
  final void Function(ChecklistItemPayload item) onStartEdit;
  final VoidCallback onCommitEdit;
  final void Function(int localId) onRemove;
  final void Function(int oldIndex, int newIndex) onReorderItem;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemExtent: kChecklistEditorRowHeight,
      itemCount: items.length,
      onReorderItem: onReorderItem,
      itemBuilder: (BuildContext context, int index) {
        final ChecklistItemPayload item = items[index];
        return _ChecklistItemRow(
          key: ValueKey<int>(item.localId),
          item: item,
          isEditing: editingLocalId == item.localId,
          editController: editController,
          editFocusNode: editFocusNode,
          dragHandle: ReorderableDragStartListener(
            index: index,
            child: const _DragHandle(),
          ),
          onStartEdit: () => onStartEdit(item),
          onCommitEdit: onCommitEdit,
          onRemove: () => onRemove(item.localId),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: (kChecklistEditorRowHeight - 24) / 2),
      child: Icon(
        Icons.drag_handle,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChecklistItemRow extends StatelessWidget {
  const _ChecklistItemRow({
    required super.key,
    required this.item,
    required this.isEditing,
    required this.editController,
    required this.editFocusNode,
    required this.dragHandle,
    required this.onStartEdit,
    required this.onCommitEdit,
    required this.onRemove,
  });

  final ChecklistItemPayload item;
  final bool isEditing;
  final TextEditingController editController;
  final FocusNode editFocusNode;
  final Widget dragHandle;
  final VoidCallback onStartEdit;
  final VoidCallback onCommitEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: SizedBox(
        height: kChecklistEditorRowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            dragHandle,
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: editController,
                      focusNode: editFocusNode,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'attachment_checklist_item_hint'.tr(),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onCommitEdit(),
                    )
                  : GestureDetector(
                      onTap: onStartEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
            ),
            InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
