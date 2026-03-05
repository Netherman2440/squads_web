import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/players/presentation/state/player_tournaments_provider.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';

class PlayerTournamentsPage extends ConsumerWidget {
  const PlayerTournamentsPage({
    super.key,
    required this.squadId,
    required this.playerId,
  });

  final String squadId;
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (squadId: squadId, playerId: playerId);
    final tournamentsAsync = ref.watch(playerTournamentsProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(playerTournamentsProvider(params).future),
        child: tournamentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: SelectableText.rich(
              TextSpan(
                text: 'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No tournaments found.')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: tournaments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return _TournamentTile(
                  squadId: squadId,
                  tournament: tournament,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TournamentTile extends StatelessWidget {
  const _TournamentTile({required this.squadId, required this.tournament});

  final String squadId;
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat(
      'dd.MM.yyyy HH:mm',
    ).format(tournament.createdAt.toLocal());

    return Card(
      child: ListTile(
        onTap: () {
          context.pushNamed(
            AppRoute.tournamentDetails.name,
            pathParameters: {
              'squadId': squadId,
              'tournamentId': tournament.tournamentId,
            },
          );
        },
        leading: const Icon(Icons.emoji_events_outlined),
        title: Text(_displayTournamentName(tournament)),
        subtitle: Text('Created: $dateText'),
        trailing: _StatusChip(status: tournament.status),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      TournamentStatus.drafting => ('Drafting', scheme.secondaryContainer),
      TournamentStatus.active => ('Active', scheme.primaryContainer),
      TournamentStatus.completed => ('Completed', scheme.tertiaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

String _displayTournamentName(Tournament tournament) {
  final value = tournament.name?.trim();
  if (value == null || value.isEmpty) {
    return 'Tournament ${tournament.createdAt.day}.${tournament.createdAt.month}';
  }
  return value;
}
