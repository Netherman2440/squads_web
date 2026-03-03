import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/application/usecases/update_match_score_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
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
      appBar: AppBar(title: const Text('Tournament')),
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
    final isWideLayout = MediaQuery.sizeOf(context).width >= 1100;
    final pointsByTeamId = <String, int>{
      for (final row in details.standings) row.tournamentTeamId: row.points,
    };
    Future<void> openTeamsEditor() async {
      await context.pushNamed(
        AppRoute.tournamentTeams.name,
        pathParameters: {
          'squadId': squadId,
          'tournamentId': tournament.tournamentId,
        },
      );

      if (context.mounted) {
        onInvalidate();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _displayTournamentName(tournament),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: tournament.status),
                  if (canManage) ...[
                    const SizedBox(height: 8),
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
                                      onPressed: () =>
                                          Navigator.pop(context, true),
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
                                  .execute(
                                    tournamentId: tournament.tournamentId,
                                  );
                              onInvalidate();
                            }
                          : null,
                      icon: const Icon(Icons.flag),
                      label: const Text('Complete'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isWideLayout)
            _WideTeamsAndStandings(
              teams: details.teams,
              standings: details.standings,
              pointsByTeamId: pointsByTeamId,
              canManage: canManage,
              onEditTeams: openTeamsEditor,
            )
          else ...[
            Row(
              children: [
                Text('Teams', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (canManage)
                  OutlinedButton.icon(
                    onPressed: openTeamsEditor,
                    icon: const Icon(Icons.groups),
                    label: const Text('Edit teams'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _TeamsStrip(
              teams: details.teams,
              isWideLayout: false,
              pointsByTeamId: pointsByTeamId,
            ),
            const SizedBox(height: 20),
            _StandingsSection(rows: details.standings),
          ],
          const SizedBox(height: 20),
          _MatchesSection(
            squadId: squadId,
            matches: details.matches,
            canManage: canManage,
            onReturnFromMatch: onInvalidate,
            onSaveScore: (matchId, homeScore, awayScore) async {
              await ref
                  .read(updateMatchScoreUseCaseProvider)
                  .execute(
                    matchId: matchId,
                    squadId: squadId,
                    homeScore: homeScore,
                    awayScore: awayScore,
                  );
              onInvalidate();
            },
            onAddMatch: details.teams.length >= 2
                ? () async {
                    final created = await _showCreateMatchDialog(
                      context,
                      ref,
                      tournament,
                      details.teams,
                    );

                    if (created != null && context.mounted) {
                      onInvalidate();
                      await context.pushNamed(
                        AppRoute.matchDetails.name,
                        pathParameters: {
                          'squadId': squadId,
                          'matchId': created.matchId,
                        },
                      );
                      if (context.mounted) {
                        onInvalidate();
                      }
                    }
                  }
                : null,
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

class _TeamsStrip extends StatelessWidget {
  const _TeamsStrip({
    required this.teams,
    required this.isWideLayout,
    required this.pointsByTeamId,
  });

  final List<TournamentTeam> teams;
  final bool isWideLayout;
  final Map<String, int> pointsByTeamId;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const Text('No teams available yet.');
    }

    if (!isWideLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: teams
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final team = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == teams.length - 1 ? 0 : 8,
                ),
                child: _TeamSummaryTile(
                  team: team,
                  compact: false,
                  teamPoints: pointsByTeamId[team.tournamentTeamId] ?? 0,
                ),
              );
            })
            .toList(growable: false),
      );
    }

    return const SizedBox.shrink();
  }
}

class _WideTeamsAndStandings extends StatelessWidget {
  const _WideTeamsAndStandings({
    required this.teams,
    required this.standings,
    required this.pointsByTeamId,
    required this.canManage,
    required this.onEditTeams,
  });

  final List<TournamentTeam> teams;
  final List<TournamentStandingRow> standings;
  final Map<String, int> pointsByTeamId;
  final bool canManage;
  final Future<void> Function() onEditTeams;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Teams', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (canManage)
                    OutlinedButton.icon(
                      onPressed: onEditTeams,
                      icon: const Icon(Icons.groups),
                      label: const Text('Edit teams'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (teams.isEmpty)
                const Text('No teams available yet.')
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    const columns = 3;
                    final tileWidth =
                        (constraints.maxWidth - (columns - 1) * spacing) /
                        columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: teams
                          .map(
                            (team) => SizedBox(
                              width: tileWidth,
                              child: _TeamSummaryTile(
                                team: team,
                                compact: true,
                                teamPoints:
                                    pointsByTeamId[team.tournamentTeamId] ?? 0,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _StandingsSection(rows: standings)),
      ],
    );
  }
}

class _StandingsSection extends StatelessWidget {
  const _StandingsSection({required this.rows});

  final List<TournamentStandingRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Standings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _StandingsTable(rows: rows),
      ],
    );
  }
}

class _MatchesSection extends StatelessWidget {
  const _MatchesSection({
    required this.squadId,
    required this.matches,
    required this.canManage,
    required this.onReturnFromMatch,
    required this.onSaveScore,
    required this.onAddMatch,
  });

  final String squadId;
  final List<Match> matches;
  final bool canManage;
  final VoidCallback onReturnFromMatch;
  final Future<void> Function(String matchId, int homeScore, int awayScore)
  onSaveScore;
  final Future<void> Function()? onAddMatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Matches', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (canManage)
              OutlinedButton.icon(
                onPressed: onAddMatch,
                icon: const Icon(Icons.sports_soccer),
                label: const Text('Add match'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          const Text('No tournament matches yet.')
        else
          ...matches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MatchTile(
                squadId: squadId,
                match: match,
                canManage: canManage,
                onReturnFromMatch: onReturnFromMatch,
                onSaveScore: onSaveScore,
              ),
            ),
          ),
      ],
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 28,
                horizontalMargin: 16,
                headingRowHeight: 44,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 48,
                columns: const [
                  DataColumn(label: Text('Team')),
                  DataColumn(label: Text('Pts'), numeric: true),
                  DataColumn(label: Text('P'), numeric: true),
                  DataColumn(label: Text('W'), numeric: true),
                  DataColumn(label: Text('D'), numeric: true),
                  DataColumn(label: Text('L'), numeric: true),
                  DataColumn(label: Text('GD'), numeric: true),
                ],
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(row.teamName)),
                          DataCell(Text('${row.points}')),
                          DataCell(Text('${row.played}')),
                          DataCell(Text('${row.wins}')),
                          DataCell(Text('${row.draws}')),
                          DataCell(Text('${row.losses}')),
                          DataCell(Text('${row.goalDifference}')),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeamSummaryTile extends StatelessWidget {
  const _TeamSummaryTile({
    required this.team,
    required this.compact,
    required this.teamPoints,
  });

  final TournamentTeam team;
  final bool compact;
  final int teamPoints;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final players = team.players;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: compact ? 9 : 10,
                  backgroundColor: _parseColor(team.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _teamName(team),
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: compact ? 19 : 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _TeamPointsBadge(points: teamPoints),
              ],
            ),
            const SizedBox(height: 8),
            if (players.isEmpty)
              Text('No players assigned.', style: textTheme.bodyMedium)
            else
              ...players.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == players.length - 1 ? 0 : 6,
                  ),
                  child: _PlayerMiniTile(player: entry.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamPointsBadge extends StatelessWidget {
  const _TeamPointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$points pts',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PlayerMiniTile extends StatelessWidget {
  const _PlayerMiniTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final position = player.position?.trim();
    final hasPosition = position != null && position.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _playerName(player),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (hasPosition)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                position,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              player.ranking.toStringAsFixed(1),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatefulWidget {
  const _MatchTile({
    required this.squadId,
    required this.match,
    required this.canManage,
    required this.onReturnFromMatch,
    required this.onSaveScore,
  });

  final String squadId;
  final Match match;
  final bool canManage;
  final VoidCallback onReturnFromMatch;
  final Future<void> Function(String matchId, int homeScore, int awayScore)
  onSaveScore;

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  late final FocusNode _homeFocusNode;
  late final FocusNode _awayFocusNode;
  var _isEditing = false;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(
      text: widget.match.homeScore?.toString() ?? '',
    );
    _awayController = TextEditingController(
      text: widget.match.awayScore?.toString() ?? '',
    );
    _homeFocusNode = FocusNode();
    _awayFocusNode = FocusNode();
    _homeController.addListener(_onScoreChanged);
    _awayController.addListener(_onScoreChanged);
  }

  @override
  void didUpdateWidget(covariant _MatchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextHome = widget.match.homeScore?.toString() ?? '';
    final nextAway = widget.match.awayScore?.toString() ?? '';
    final matchChanged = oldWidget.match.matchId != widget.match.matchId;

    if (matchChanged || !_isEditing) {
      if (_homeController.text != nextHome) {
        _homeController.text = nextHome;
      }
      if (_awayController.text != nextAway) {
        _awayController.text = nextAway;
      }
    }

    if (matchChanged) {
      _isEditing = false;
      _isSaving = false;
    }
  }

  @override
  void dispose() {
    _homeController
      ..removeListener(_onScoreChanged)
      ..dispose();
    _awayController
      ..removeListener(_onScoreChanged)
      ..dispose();
    _homeFocusNode.dispose();
    _awayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.match.homeTeam?.name?.trim().isNotEmpty == true
        ? widget.match.homeTeam!.name!
        : 'Home';
    final away = widget.match.awayTeam?.name?.trim().isNotEmpty == true
        ? widget.match.awayTeam!.name!
        : 'Away';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isEditing ? null : _openMatchDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$home vs $away',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayMatchDate(widget.match.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _ScoreBox(
                controller: _homeController,
                focusNode: _homeFocusNode,
                isEditing: _isEditing,
                onTap: widget.canManage
                    ? () => _startEditing(focusHomeScore: true)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                '-',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              _ScoreBox(
                controller: _awayController,
                focusNode: _awayFocusNode,
                isEditing: _isEditing,
                onTap: widget.canManage
                    ? () => _startEditing(focusHomeScore: false)
                    : null,
              ),
              if (widget.canManage &&
                  _isEditing &&
                  (_hasValidScores || _isSaving)) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSave ? _saveScore : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _onScoreChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  int? _parseScore(String rawValue) {
    final value = int.tryParse(rawValue.trim());
    if (value == null || value < 0) {
      return null;
    }
    return value;
  }

  bool get _hasValidScores =>
      _parseScore(_homeController.text) != null &&
      _parseScore(_awayController.text) != null;

  bool get _canSave => !_isSaving && _hasValidScores;

  void _startEditing({required bool focusHomeScore}) {
    if (!widget.canManage) {
      return;
    }

    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (focusHomeScore) {
        _homeFocusNode.requestFocus();
      } else {
        _awayFocusNode.requestFocus();
      }
    });
  }

  Future<void> _openMatchDetails() async {
    await context.pushNamed(
      AppRoute.matchDetails.name,
      pathParameters: {
        'squadId': widget.squadId,
        'matchId': widget.match.matchId,
      },
    );
    if (context.mounted) {
      widget.onReturnFromMatch();
    }
  }

  Future<void> _saveScore() async {
    final homeScore = _parseScore(_homeController.text);
    final awayScore = _parseScore(_awayController.text);
    if (homeScore == null || awayScore == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSaveScore(widget.match.matchId, homeScore, awayScore);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Match score updated.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update score: $error')));
    }
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final score = controller.text.trim();
    final scheme = Theme.of(context).colorScheme;
    final hasScore = score.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          border: Border.all(
            color: hasScore
                ? scheme.primary.withValues(alpha: 0.6)
                : scheme.outlineVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: isEditing
            ? TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 2,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Text(
                hasScore ? score : '',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
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

String _playerName(Player player) {
  final value = player.name.trim();
  if (value.isEmpty) {
    return 'Player';
  }
  return value;
}

String _displayMatchDate(DateTime value) {
  return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
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
