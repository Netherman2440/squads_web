import 'package:flutter/material.dart';

class ScoreBox extends StatelessWidget {
  const ScoreBox({
    super.key,
    required this.label,
    required this.score,
  });

  final String label;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score?.toString() ?? '-',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
