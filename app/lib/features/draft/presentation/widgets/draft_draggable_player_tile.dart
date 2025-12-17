import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app/features/players/domain/entities/player.dart';

class DraftDraggablePlayerTile extends StatelessWidget {
  const DraftDraggablePlayerTile({
    super.key,
    required this.player,
    required this.trailing,
    this.onTap,
    this.dragData,
  });

  final Player player;
  final Widget trailing;
  final VoidCallback? onTap;
  final Object? dragData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difference = player.score - player.baseScore;

    final tile = Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          ),
        ),
        title: Text(player.name),
        subtitle: Row(
          children: [
            if (player.position != null && player.position!.trim().isNotEmpty) ...[
              Icon(
                Icons.sports_soccer,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(player.position!),
              const SizedBox(width: 12),
            ],
            Icon(
              Icons.star_border,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text('Base: ${player.baseScore}'),
            const SizedBox(width: 12),
            Icon(
              Icons.insights,
              size: 16,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Text('Score: ${player.score.toStringAsFixed(2)}'),
            if (difference.abs() > 0) ...[
              const SizedBox(width: 12),
              _ScoreDifference(difference: difference),
            ],
          ],
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );

    final data = dragData;
    if (data == null) {
      return tile;
    }

    final feedback = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: tile,
        ),
      ),
    );

    final childWhenDragging = Opacity(
      opacity: 0.4,
      child: tile,
    );

    if (_shouldUseImmediateDrag) {
      return Draggable<Object>(
        data: data,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: tile,
      );
    }

    return LongPressDraggable<Object>(
      data: data,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: tile,
    );
  }
}

bool get _shouldUseImmediateDrag {
  if (kIsWeb) {
    return true;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return false;
  }
}

class _ScoreDifference extends StatelessWidget {
  const _ScoreDifference({required this.difference});

  final double difference;

  @override
  Widget build(BuildContext context) {
    final isPositiveOrFlat = difference >= 0;
    final color = isPositiveOrFlat ? Colors.green : Colors.red;
    final formattedDifference = '${difference >= 0 ? '+' : ''}'
        '${difference.toStringAsFixed(2)}';

    return Row(
      children: [
        Icon(
          isPositiveOrFlat ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          formattedDifference,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
