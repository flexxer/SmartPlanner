import 'package:flutter/material.dart';

/// Section title row inside an expanded [TaskExpandableTile].
class TaskTileSectionHeader extends StatelessWidget {
  const TaskTileSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: iconColor ?? colors.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
