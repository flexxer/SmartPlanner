import 'package:flutter/material.dart';

/// Compact badge for task list metadata (priority, links, progress).
class TaskBadge extends StatelessWidget {
  const TaskBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.onTap,
    this.iconOnly = false,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Icon-only chip with [label] as tooltip (dashboard compact mode).
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final Widget chip = Container(
      padding: iconOnly
          ? const EdgeInsets.all(5)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconOnly
          ? Icon(
              icon ?? Icons.info_outline,
              size: 14,
              color: foregroundColor,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 14, color: foregroundColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
    );

    final Widget content = Tooltip(
      message: label,
      child: chip,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}
