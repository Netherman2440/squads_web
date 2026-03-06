import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';
import 'package:app/features/tournaments/presentation/state/tournament_providers.dart';

class SquadTournamentsPage extends ConsumerWidget {
  const SquadTournamentsPage({super.key, required this.squadId});

  final String squadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(squadTournamentsProvider(squadId));
    final squadAsync = ref.watch(squadDetailProvider(squadId));
    final canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Turnieje')),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: SelectableText(
            'Nie udało się wczytać turniejów: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (tournaments) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(squadTournamentsProvider(squadId));
              await ref.read(squadTournamentsProvider(squadId).future);
            },
            child: tournaments.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Brak turniejów. Utwórz pierwszy.')),
                    ],
                  )
                : ListView.separated(
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
                  ),
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                context.pushNamed(
                  AppRoute.tournamentCreate.name,
                  pathParameters: {'squadId': squadId},
                );
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('Utwórz turniej'),
            )
          : null,
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
        subtitle: Text('Utworzono: $dateText'),
        trailing: _StatusLabel(status: tournament.status),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      TournamentStatus.drafting => (
        'Nie wybrano drużyn',
        scheme.onSurfaceVariant,
      ),
      TournamentStatus.active => ('Aktywny', scheme.primary),
      TournamentStatus.completed => ('Zakończony', Colors.grey),
    };

    return Text(
      label,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

String _displayTournamentName(Tournament tournament) {
  final value = tournament.name?.trim();
  if (value == null || value.isEmpty) {
    return 'Turniej ${tournament.createdAt.day}.${tournament.createdAt.month}';
  }
  return value;
}
