import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/presentation/controllers/players_notifier.dart';

class PlayersListWidget extends ConsumerWidget {
  const PlayersListWidget({
    super.key,
    required this.players,
    required this.squadId,
  });

  final List<Player> players;
  final String squadId;

  bool _canManagePlayers(WidgetRef ref) {
    final authEntity = ref.read(authStateProvider).value;
    if (authEntity == null || authEntity.isAnonymous) {
      return false;
    }
    // For now we assume that role check is done on backend (RLS).
    // UI will just show actions for authenticated users.
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canManage = _canManagePlayers(ref);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];

        return Card(
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
                Text('Base: ${player.baseScore}'),
                const SizedBox(width: 12),
                Icon(
                  Icons.insights,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Text('Score: ${player.score.toStringAsFixed(2)}'),
              ],
            ),
            trailing: canManage
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete player',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete player'),
                          content: Text(
                            'Are you sure you want to delete ${player.name}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) {
                        return;
                      }

                      await ref
                          .read(playersNotifierProvider.notifier)
                          .deletePlayer(
                            squadId: squadId,
                            playerId: player.playerId,
                          );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}


