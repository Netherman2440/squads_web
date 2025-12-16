import 'package:flutter/material.dart';

import 'package:app/features/matches/domain/entities/team.dart';
import 'package:app/features/players/domain/entities/player.dart';

class TeamRosterList extends StatelessWidget {
  const TeamRosterList({
    super.key,
    required this.team,
    required this.onPlayerTap,
  });

  final Team team;
  final void Function(Player player) onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final players = team.players;

    if (players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No players assigned to this team yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final player = players[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(player.name),
          subtitle: Text('Score: ${player.score.toStringAsFixed(1)}'),
          onTap: () => onPlayerTap(player),
        );
      },
    );
  }
}
