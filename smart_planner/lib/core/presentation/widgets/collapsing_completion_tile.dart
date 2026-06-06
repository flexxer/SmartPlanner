import 'package:flutter/material.dart';
import 'package:smart_planner/core/presentation/widgets/sliding_completion_list.dart';

/// Runs [onAfterCollapse] after a collapse animation (variable-height lists).
class CollapsingCompletionTile extends StatefulWidget {
  const CollapsingCompletionTile({
    required this.onAfterCollapse,
    required this.builder,
    super.key,
  });

  final VoidCallback onAfterCollapse;
  final Widget Function(VoidCallback onToggle) builder;

  @override
  State<CollapsingCompletionTile> createState() =>
      _CollapsingCompletionTileState();
}

class _CollapsingCompletionTileState extends State<CollapsingCompletionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CompletionListMotion.slideDuration,
      value: 1,
    );
    _sizeFactor = CurvedAnimation(
      parent: _controller,
      curve: CompletionListMotion.slideCurve,
    );
  }

  @override
  void didUpdateWidget(covariant CollapsingCompletionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy && _controller.value < 1.0) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onToggle() async {
    if (_busy) {
      return;
    }
    _busy = true;
    await _controller.reverse(from: 1);
    if (!mounted) {
      return;
    }
    widget.onAfterCollapse();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeFactor,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _sizeFactor,
        child: widget.builder(_onToggle),
      ),
    );
  }
}

/// Checkbox zone for task tiles (dashboard, linked lists).
class CompletionToggleTarget extends StatelessWidget {
  const CompletionToggleTarget({
    required this.isCompleted,
    required this.onToggle,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(12),
    ),
    super.key,
  });

  final bool isCompleted;
  final VoidCallback onToggle;
  final BorderRadius borderRadius;

  static const double minTouchTarget = 48;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
        child: SizedBox(
          width: minTouchTarget,
          height: minTouchTarget,
          child: Center(
            child: IgnorePointer(
              child: Checkbox(
                value: isCompleted,
                onChanged: (_) {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
