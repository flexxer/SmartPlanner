import 'package:flutter/material.dart';
import 'package:smart_planner/core/theme/app_theme.dart';

/// Inline message with action for calendar picker error / permission states.
class CalendarPickerMessage extends StatelessWidget {
  const CalendarPickerMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.compact = false,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// When true, uses plain text + left-aligned button (task form chips).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      );
    }

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.insetCardDecoration(colors, borderRadius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
