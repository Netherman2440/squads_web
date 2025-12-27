import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/app_router.dart';

import 'package:app/features/players/domain/entities/player.dart';

class PlayersListWidget extends StatelessWidget {
  const PlayersListWidget({
    super.key,
    required this.players,
    required this.squadId,
  });

  final List<Player> players;
  final String squadId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final difference = player.ranking - player.baseRanking;

        return Card(
          child: ListTile(
            onTap: () {
              context.pushNamed(
                AppRoute.playerDetails.name,
                pathParameters: {
                  'squadId': squadId,
                  'playerId': player.playerId,
                },
              );
            },
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
                Icon(
                  Icons.insights,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Text('Ranking: ${player.ranking.toStringAsFixed(2)}'),
                if (difference.abs() > 0) ...[
                  const SizedBox(width: 12),
                  _RankingDifference(
                    difference: difference,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RankingDifference extends StatelessWidget {
  const _RankingDifference({
    required this.difference,
  });

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


