import 'package:flutter/material.dart';

class DangerActionButton extends StatelessWidget {
  const DangerActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.minWidth = 200,
  });

  final String label;
  final VoidCallback? onPressed;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
          onPressed: onPressed,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, softWrap: false),
          ),
        ),
      ),
    );
  }
}
