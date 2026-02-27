import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/application/dto/tournament_details_dto.dart';
import 'package:app/features/tournaments/application/usecases/complete_tournament_usecase.dart';
import 'package:app/features/tournaments/application/usecases/create_tournament_match_usecase.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';
import 'package:app/features/tournaments/presentation/state/tournament_providers.dart';

class TournamentDetailsPage extends ConsumerWidget {
  const TournamentDetailsPage({
    super.key,
    required this.squadId,
    required this.tournamentId,
  });

  final String squadId;
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(tournamentDetailsProvider(tournamentId));
    final squadAsync = ref.watch(squadDetailProvider(squadId));
    final canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(tournamentDetailsProvider(tournamentId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: SelectableText(
            'Failed to load tournament: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (details) => _DetailsBody(
          squadId: squadId,
          details: details,
          canManage: canManage,
          onInvalidate: () {
            ref.invalidate(tournamentDetailsProvider(tournamentId));
            ref.invalidate(squadTournamentsProvider(squadId));
          },
        ),
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({
    required this.squadId,
    required this.details,
    required this.canManage,
    required this.onInvalidate,
  });

  final String squadId;
  final TournamentDetailsDto details;
  final bool canManage;
  final VoidCallback onInvalidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = details.tournament;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _displayTournamentName(tournament),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _StatusChip(status: tournament.status),
            ],
          ),
          const SizedBox(height: 12),
          if (canManage)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: details.teams.length >= 2
                      ? () async {
                          final created = await _showCreateMatchDialog(
                            context,
                            ref,
                            tournament,
                            details.teams,
                          );

                          if (created != null && context.mounted) {
                            onInvalidate();
                            context.pushNamed(
                              AppRoute.matchDetails.name,
                              pathParameters: {
                                'squadId': squadId,
                                'matchId': created.matchId,
                              },
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Add match'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(
                      AppRoute.tournamentTeams.name,
                      pathParameters: {
                        'squadId': squadId,
                        'tournamentId': tournament.tournamentId,
                      },
                    );
                  },
                  icon: const Icon(Icons.groups),
                  label: const Text('Edit teams'),
                ),
                OutlinedButton.icon(
                  onPressed: tournament.status == TournamentStatus.active
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Complete tournament?'),
                              content: const Text(
                                'This will finalize tournament ranking changes.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Complete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) {
                            return;
                          }

                          await ref
                              .read(completeTournamentUseCaseProvider)
                              .execute(tournamentId: tournament.tournamentId);
                          onInvalidate();
                        }
                      : null,
                  icon: const Icon(Icons.flag),
                  label: const Text('Complete'),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Text('Standings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _StandingsTable(rows: details.standings),
          const SizedBox(height: 20),
          Text('Teams', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...details.teams.map((team) => _TeamSummaryTile(team: team)),
          const SizedBox(height: 20),
          Text('Matches', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (details.matches.isEmpty)
            const Text('No tournament matches yet.')
          else
            ...details.matches.map(
              (match) => _MatchTile(squadId: squadId, match: match),
            ),
          const SizedBox(height: 20),
          Text('Draft history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (details.drafts.isEmpty)
            const Text('No drafts saved yet.')
          else
            ...details.drafts.map(
              (draft) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(
                    'Draft ${DateFormat('dd.MM.yyyy HH:mm').format(draft.createdAt.toLocal())}',
                  ),
                  subtitle: Text(
                    'status: ${draft.status}, proposals: ${draft.proposalsCount}',
                  ),
                  onTap: () {
                    context.pushNamed(
                      AppRoute.tournamentDraftById.name,
                      pathParameters: {
                        'squadId': squadId,
                        'tournamentId': tournament.tournamentId,
                        'tournamentDraftId': draft.tournamentDraftId,
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<Match?> _showCreateMatchDialog(
    BuildContext context,
    WidgetRef ref,
    Tournament tournament,
    List<TournamentTeam> teams,
  ) async {
    if (teams.length < 2) {
      return null;
    }

    var homeId = teams[0].tournamentTeamId;
    var awayId = teams[1].tournamentTeamId;

    return showDialog<Match>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add tournament match'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: homeId,
                    decoration: const InputDecoration(labelText: 'Home team'),
                    items: teams
                        .map(
                          (team) => DropdownMenuItem<String>(
                            value: team.tournamentTeamId,
                            child: Text(_teamName(team)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        homeId = value;
                        if (homeId == awayId) {
                          awayId = teams
                              .firstWhere(
                                (team) => team.tournamentTeamId != homeId,
                              )
                              .tournamentTeamId;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: awayId,
                    decoration: const InputDecoration(labelText: 'Away team'),
                    items: teams
                        .map(
                          (team) => DropdownMenuItem<String>(
                            value: team.tournamentTeamId,
                            child: Text(_teamName(team)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        awayId = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: homeId == awayId
                      ? null
                      : () async {
                          final created = await ref
                              .read(createTournamentMatchUseCaseProvider)
                              .execute(
                                tournamentId: tournament.tournamentId,
                                homeTournamentTeamId: homeId,
                                awayTournamentTeamId: awayId,
                              );

                          if (context.mounted) {
                            Navigator.pop(context, created);
                          }
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.rows});

  final List<TournamentStandingRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No standings yet.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Team')),
          DataColumn(label: Text('W')),
          DataColumn(label: Text('L')),
          DataColumn(label: Text('GD')),
        ],
        rows: rows
            .map(
              (row) => DataRow(
                cells: [
                  DataCell(Text(row.teamName)),
                  DataCell(Text('${row.wins}')),
                  DataCell(Text('${row.losses}')),
                  DataCell(Text('${row.goalDifference}')),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TeamSummaryTile extends StatelessWidget {
  const _TeamSummaryTile({required this.team});

  final TournamentTeam team;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _parseColor(team.color)),
        title: Text(_teamName(team)),
        subtitle: Text('Players: ${team.players.length}'),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.squadId, required this.match});

  final String squadId;
  final Match match;

  @override
  Widget build(BuildContext context) {
    final home = match.homeTeam?.name?.trim().isNotEmpty == true
        ? match.homeTeam!.name!
        : 'Home';
    final away = match.awayTeam?.name?.trim().isNotEmpty == true
        ? match.awayTeam!.name!
        : 'Away';
    final score = (match.homeScore != null && match.awayScore != null)
        ? '${match.homeScore}:${match.awayScore}'
        : '-:-';

    return Card(
      child: ListTile(
        title: Text('$home vs $away'),
        subtitle: Text(score),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.pushNamed(
            AppRoute.matchDetails.name,
            pathParameters: {'squadId': squadId, 'matchId': match.matchId},
          );
        },
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
    return 'Tournament';
  }
  return value;
}

String _teamName(TournamentTeam team) {
  final value = team.name?.trim();
  if (value == null || value.isEmpty) {
    return 'Team';
  }
  return value;
}

Color _parseColor(String? colorHex) {
  if (colorHex == null || colorHex.isEmpty) {
    return Colors.grey;
  }

  try {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('0xFF$hex'));
  } catch (_) {
    return Colors.grey;
  }
}
