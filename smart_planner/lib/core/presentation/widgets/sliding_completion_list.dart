import 'package:flutter/material.dart';

/// Shared motion constants for completion-toggle lists.
abstract final class CompletionListMotion {
  static const Duration slideDuration = Duration(milliseconds: 340);
  static const Duration styleDuration = Duration(milliseconds: 220);
  static const Curve slideCurve = Curves.easeInOutCubic;
  static const Curve styleCurve = Curves.easeOutCubic;
}

/// Estimates checkbox-row height for [text] up to [maxLines] (used by [SlidingCompletionList]).
double completionCheckboxRowExtent({
  required BuildContext context,
  required String text,
  required double maxTextWidth,
  TextStyle? textStyle,
  int maxLines = 2,
  double verticalPadding = 8,
  double minHeight = 28,
}) {
  final TextStyle style =
      textStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  final double width = maxTextWidth.isFinite && maxTextWidth > 0
      ? maxTextWidth
      : MediaQuery.sizeOf(context).width - 80;

  final TextPainter painter = TextPainter(
    text: TextSpan(text: text.isEmpty ? ' ' : text, style: style),
    textDirection: Directionality.of(context),
    maxLines: maxLines,
  )..layout(maxWidth: width);

  return (painter.height + verticalPadding).clamp(minHeight, double.infinity);
}

/// Moves [isCompleted] items after all uncompleted items (stable order within groups).
List<T> partitionCompletedLast<T>(
  List<T> items,
  bool Function(T item) isCompleted,
) {
  return <T>[
    ...items.where((T item) => !isCompleted(item)),
    ...items.where((T item) => isCompleted(item)),
  ];
}

/// Fixed-height list where completed items slide to the end when [moveCompletedToEnd].
class SlidingCompletionList<T> extends StatefulWidget {
  const SlidingCompletionList({
    required this.items,
    required this.idOf,
    required this.isCompleted,
    required this.toggleItem,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onToggle,
    this.moveCompletedToEnd = true,
    this.emptyBuilder,
    super.key,
  });

  final List<T> items;
  final int Function(T item) idOf;
  final bool Function(T item) isCompleted;
  final T Function(T item) toggleItem;
  final double Function(T item) itemExtent;
  final Widget Function(
    BuildContext context,
    T item, {
    required bool syncStyleWithSlide,
    required Animation<double>? styleProgress,
    required VoidCallback onToggle,
  }) itemBuilder;
  final ValueChanged<T> onToggle;
  final bool moveCompletedToEnd;
  final WidgetBuilder? emptyBuilder;

  @override
  State<SlidingCompletionList<T>> createState() =>
      _SlidingCompletionListState<T>();
}

class _SlidingCompletionListState<T> extends State<SlidingCompletionList<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reorderController;
  late final Animation<double> _reorderProgress;

  late List<T> _items;
  Map<int, int>? _slideFromIndexByLocalId;
  Map<int, double>? _slideFromTopByLocalId;
  int? _toggledId;
  bool _ignoreNextExternalSync = false;

  @override
  void initState() {
    super.initState();
    _reorderController = AnimationController(
      vsync: this,
      duration: CompletionListMotion.slideDuration,
    );
    _reorderProgress = CurvedAnimation(
      parent: _reorderController,
      curve: CompletionListMotion.slideCurve,
    );
    _items = List<T>.from(widget.items);
  }

  @override
  void dispose() {
    _reorderController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlidingCompletionList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ignoreNextExternalSync) {
      _ignoreNextExternalSync = false;
      return;
    }
    if (_itemsEqual(_items, widget.items)) {
      return;
    }
    _reorderController.stop();
    setState(() {
      _items = List<T>.from(widget.items);
      _slideFromIndexByLocalId = null;
      _slideFromTopByLocalId = null;
      _toggledId = null;
    });
  }

  List<double> _offsetsFor(List<T> items) {
    final List<double> offsets = <double>[];
    double top = 0;
    for (final T item in items) {
      offsets.add(top);
      top += widget.itemExtent(item);
    }
    return offsets;
  }

  bool _itemsEqual(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (widget.idOf(a[i]) != widget.idOf(b[i]) ||
          widget.isCompleted(a[i]) != widget.isCompleted(b[i])) {
        return false;
      }
    }
    return true;
  }

  List<T> _displayItems(List<T> items) {
    if (!widget.moveCompletedToEnd) {
      return items;
    }
    return partitionCompletedLast(items, widget.isCompleted);
  }

  List<_RowLayout<T>> _rowLayouts() {
    final List<T> display = _displayItems(_items);
    final List<double> offsets = _offsetsFor(display);

    final List<_RowLayout<T>> rows = <_RowLayout<T>>[];
    for (int index = 0; index < display.length; index++) {
      final T item = display[index];
      final int id = widget.idOf(item);
      rows.add(
        _RowLayout<T>(
          item: item,
          index: index,
          targetTop: offsets[index],
          slideFromIndex: _slideFromIndexByLocalId?[id] ?? index,
          slideFromTop: _slideFromTopByLocalId?[id] ?? offsets[index],
        ),
      );
    }

    rows.sort((_RowLayout<T> a, _RowLayout<T> b) {
      final bool aMoves = a.slideFromIndex != a.index;
      final bool bMoves = b.slideFromIndex != b.index;
      if (aMoves != bMoves) {
        return aMoves ? 1 : -1;
      }
      return a.index.compareTo(b.index);
    });
    return rows;
  }

  double get _totalHeight {
    double height = 0;
    for (final T item in _displayItems(_items)) {
      height += widget.itemExtent(item);
    }
    return height;
  }

  void _handleToggle(T item) {
    if (_reorderController.isAnimating) {
      return;
    }

    final int id = widget.idOf(item);
    final List<T> display = _displayItems(_items);
    final int oldIndex = display.indexWhere((T i) => widget.idOf(i) == id);
    if (oldIndex < 0) {
      return;
    }

    final T toggled = widget.toggleItem(item);
    final List<T> working = List<T>.from(_items);
    final int sourceIndex =
        working.indexWhere((T i) => widget.idOf(i) == id);
    if (sourceIndex < 0) {
      return;
    }
    working[sourceIndex] = toggled;

    final List<T> reordered = widget.moveCompletedToEnd
        ? partitionCompletedLast(working, widget.isCompleted)
        : working;
    final List<T> newDisplay = _displayItems(reordered);
    final int newIndex =
        newDisplay.indexWhere((T i) => widget.idOf(i) == id);

    if (newIndex != oldIndex) {
      final List<double> oldOffsets = _offsetsFor(display);
      final Map<int, int> oldIndexById = <int, int>{
        for (int i = 0; i < display.length; i++) widget.idOf(display[i]): i,
      };
      final Map<int, double> oldTopById = <int, double>{
        for (int i = 0; i < display.length; i++)
          widget.idOf(display[i]): oldOffsets[i],
      };
      setState(() {
        _items = reordered;
        _slideFromIndexByLocalId = oldIndexById;
        _slideFromTopByLocalId = oldTopById;
        _toggledId = id;
      });
      _reorderController.forward(from: 0).whenComplete(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _slideFromIndexByLocalId = null;
          _slideFromTopByLocalId = null;
          _toggledId = null;
        });
      });
    } else {
      setState(() => _items[sourceIndex] = toggled);
    }

    _ignoreNextExternalSync = true;
    widget.onToggle(toggled);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    final bool isReordering = _slideFromIndexByLocalId != null;
    final List<_RowLayout<T>> rows = _rowLayouts();

    return SizedBox(
      height: _totalHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: rows
            .map(
              (_RowLayout<T> row) => _SlidingCompletionRow<T>(
                key: ValueKey<int>(widget.idOf(row.item)),
                item: row.item,
                targetTop: row.targetTop,
                slideFromTop: row.slideFromTop,
                height: widget.itemExtent(row.item),
                reorderProgress: _reorderProgress,
                isReordering: isReordering,
                syncStyleWithSlide:
                    isReordering && widget.idOf(row.item) == _toggledId,
                itemBuilder: widget.itemBuilder,
                onToggle: () => _handleToggle(row.item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RowLayout<T> {
  const _RowLayout({
    required this.item,
    required this.index,
    required this.targetTop,
    required this.slideFromIndex,
    required this.slideFromTop,
  });

  final T item;
  final int index;
  final double targetTop;
  final int slideFromIndex;
  final double slideFromTop;
}

class _SlidingCompletionRow<T> extends StatelessWidget {
  const _SlidingCompletionRow({
    required super.key,
    required this.item,
    required this.targetTop,
    required this.slideFromTop,
    required this.height,
    required this.reorderProgress,
    required this.isReordering,
    required this.syncStyleWithSlide,
    required this.itemBuilder,
    required this.onToggle,
  });

  final T item;
  final double targetTop;
  final double slideFromTop;
  final double height;
  final Animation<double> reorderProgress;
  final bool isReordering;
  final bool syncStyleWithSlide;
  final Widget Function(
    BuildContext context,
    T item, {
    required bool syncStyleWithSlide,
    required Animation<double>? styleProgress,
    required VoidCallback onToggle,
  }) itemBuilder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget row = RepaintBoundary(
      child: itemBuilder(
        context,
        item,
        syncStyleWithSlide: syncStyleWithSlide,
        styleProgress: syncStyleWithSlide ? reorderProgress : null,
        onToggle: onToggle,
      ),
    );

    if (!isReordering || slideFromTop == targetTop) {
      return Positioned(
        top: targetTop,
        left: 0,
        right: 0,
        height: height,
        child: Align(
          alignment: Alignment.topCenter,
          child: row,
        ),
      );
    }

    return AnimatedBuilder(
      animation: reorderProgress,
      builder: (BuildContext context, Widget? child) {
        final double top =
            slideFromTop + (targetTop - slideFromTop) * reorderProgress.value;
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: Align(
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: row,
    );
  }
}

/// Lerps active/completed [TextStyle] while a row slides.
class CompletionTextLabel extends StatelessWidget {
  const CompletionTextLabel({
    required this.text,
    required this.isCompleted,
    required this.activeStyle,
    required this.completedStyle,
    this.syncStyleWithSlide = false,
    this.styleProgress,
    this.maxLines = 2,
    super.key,
  });

  final String text;
  final bool isCompleted;
  final TextStyle activeStyle;
  final TextStyle completedStyle;
  final bool syncStyleWithSlide;
  final Animation<double>? styleProgress;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (syncStyleWithSlide && styleProgress != null) {
      return AnimatedBuilder(
        animation: styleProgress!,
        builder: (BuildContext context, Widget? child) {
          final double t =
              isCompleted ? styleProgress!.value : 1 - styleProgress!.value;
          return Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle.lerp(activeStyle, completedStyle, t),
          );
        },
      );
    }

    return AnimatedDefaultTextStyle(
      duration: CompletionListMotion.styleDuration,
      curve: CompletionListMotion.styleCurve,
      style: isCompleted ? completedStyle : activeStyle,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
