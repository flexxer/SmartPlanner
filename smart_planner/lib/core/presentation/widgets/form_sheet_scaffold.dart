import 'package:flutter/material.dart';

/// Shared bottom-sheet layout: safe area, keyboard inset, scrollable form body.
class FormSheetScaffold extends StatelessWidget {
  const FormSheetScaffold({
    required this.title,
    required this.children,
    this.onDelete,
    this.deleteEnabled = true,
    this.headerChildren = const <Widget>[],
    super.key,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onDelete;
  final bool deleteEnabled;
  final List<Widget> headerChildren;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      onPressed: deleteEnabled ? onDelete : null,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colors.error,
                      ),
                    ),
                ],
              ),
              ...headerChildren,
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary save button with optional loading spinner.
class FormSheetSaveButton extends StatelessWidget {
  const FormSheetSaveButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool canPress = enabled && onPressed != null;

    return FilledButton(
      onPressed: canPress ? onPressed : null,
      child: !enabled
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
