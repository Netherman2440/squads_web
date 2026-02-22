import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/features/matches/application/dto/player_dto.dart';

class MatchPlayerTile extends StatelessWidget {
  const MatchPlayerTile({
    super.key,
    required this.player,
    required this.trailing,
    this.compact = false,
    this.onTap,
    this.dragData,
    this.snapshotRanking,
    this.onDragStarted,
    this.onDragEnd,
  });

  final PlayerDto player;
  final Widget trailing;
  final bool compact;
  final VoidCallback? onTap;
  final Object? dragData;

  /// If provided, this ranking is shown instead of player.ranking
  final double? snapshotRanking;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    // In match history, we should show the snapshot ranking if available.
    final displayRanking = snapshotRanking ?? player.ranking;
    final theme = Theme.of(context);
    final hasTrailing = trailing is! SizedBox;
    final scoreText = displayRanking.toStringAsFixed(2);

    final tile = Card(
      child: compact
          ? InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        player.name.isNotEmpty
                            ? player.name[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              softWrap: true,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            scoreText,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasTrailing) ...[const SizedBox(width: 8), trailing],
                  ],
                ),
              ),
            )
          : ListTile(
              dense: false,
              visualDensity: VisualDensity.standard,
              leading: CircleAvatar(
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                ),
              ),
              title: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(scoreText),
              trailing: trailing,
              onTap: onTap,
            ),
    );

    final data = dragData;
    if (data == null) {
      return tile;
    }

    final feedback = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 320 : 520),
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
        onDragStarted: onDragStarted,
        onDragEnd: (_) => onDragEnd?.call(),
        childWhenDragging: childWhenDragging,
        child: tile,
      );
    }

    return LongPressDraggable<Object>(
      data: data,
      feedback: feedback,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
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

// Intentionally no ranking change indicator here. Match details should show
// only the snapshot ranking.
