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

    final tile = Card(
      child: ListTile(
        dense: compact,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        contentPadding: compact
            ? const EdgeInsets.symmetric(horizontal: 8)
            : null,
        leading: CircleAvatar(
          radius: compact ? 14 : null,
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: compact ? theme.textTheme.labelSmall : null,
          ),
        ),
        title: Text(
          player.name,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: compact ? theme.textTheme.bodyMedium : null,
        ),
        subtitle: compact ? null : Text(displayRanking.toStringAsFixed(2)),
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
