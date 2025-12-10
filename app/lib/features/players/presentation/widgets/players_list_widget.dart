import 'package:flutter/material.dart';

import '../../domain/entities/player.dart';

class PlayersListWidget extends StatelessWidget {
  const PlayersListWidget({
    super.key,
    required this.players,
    required this.canManage,
    required this.onDelete,
  });

  final List<Player> players;
  final bool canManage;
  final Future<void> Function(String playerId) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : '?'),
            ),
            title: Text(player.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (player.position != null && player.position!.isNotEmpty)
                  Text('Position: ${player.position}'),
                Text('Base score: ${player.baseScore}'),
                Text('Score: ${player.score.toStringAsFixed(1)}'),
              ],
            ),
            trailing: canManage
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, player),
                    tooltip: 'Delete player',
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete player'),
        content: Text('Are you sure you want to delete ${player.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onDelete(player.id);
    }
  }
}
