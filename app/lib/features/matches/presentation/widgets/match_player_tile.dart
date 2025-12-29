import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/features/players/domain/entities/player.dart';

class MatchPlayerTile extends StatelessWidget {
  const MatchPlayerTile({
    super.key,
    required this.player,
    required this.trailing,
    this.onTap,
    this.dragData,
    this.snapshotRanking,
  });

  final Player player;
  final Widget trailing;
  final VoidCallback? onTap;
  final Object? dragData;

  /// If provided, this ranking is shown instead of player.ranking
  final double? snapshotRanking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // In match history, we should show the snapshot ranking if available.
    final displayRanking = snapshotRanking ?? player.ranking;

    // Difference from base ranking (maybe not relevant for historical match, but okay for now)
    final difference = displayRanking - player.baseRanking;

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
            if (player.position != null &&
                player.position!.trim().isNotEmpty) ...[
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
            Text('Base: ${player.baseRanking}'),
            const SizedBox(width: 12),
            Icon(Icons.insights, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 4),
            Text('Ranking: ${displayRanking.toStringAsFixed(2)}'),
            // Only show diff if it's current ranking, or maybe just always?
            // User didn't specify, but keeping it consistent with draft tile.
            if (difference.abs() > 0) ...[
              const SizedBox(width: 12),
              _RankingDifference(difference: difference),
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
        child: Opacity(opacity: 0.9, child: tile),
      ),
    );

    final childWhenDragging = Opacity(opacity: 0.4, child: tile);

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

class _RankingDifference extends StatelessWidget {
  const _RankingDifference({required this.difference});

  final double difference;

  @override
  Widget build(BuildContext context) {
    final isPositiveOrFlat = difference >= 0;
    final color = isPositiveOrFlat ? Colors.green : Colors.red;
    final formattedDifference =
        '${difference >= 0 ? '+' : ''}'
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
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
