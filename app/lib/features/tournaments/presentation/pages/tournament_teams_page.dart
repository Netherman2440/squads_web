import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/application/usecases/update_tournament_teams_usecase.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';
import 'package:app/features/tournaments/presentation/state/tournament_providers.dart';

class TournamentTeamsPage extends ConsumerStatefulWidget {
  const TournamentTeamsPage({
    super.key,
    required this.squadId,
    required this.tournamentId,
  });

  final String squadId;
  final String tournamentId;

  @override
  ConsumerState<TournamentTeamsPage> createState() =>
      _TournamentTeamsPageState();
}

class _TournamentTeamsPageState extends ConsumerState<TournamentTeamsPage> {
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  late List<TournamentTeam> _teams;
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _colorControllers = {};
  final Map<String, String> _playerAssignments = {};
  final Map<String, Player> _playersById = {};

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _colorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initFromTeams(List<TournamentTeam> teams) {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _colorControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
    _colorControllers.clear();
    _playerAssignments.clear();
    _playersById.clear();

    _teams = teams;

    for (final team in teams) {
      _nameControllers[team.tournamentTeamId] = TextEditingController(
        text: team.name ?? '',
      );
      _colorControllers[team.tournamentTeamId] = TextEditingController(
        text: team.color ?? '',
      );

      for (final player in team.players) {
        _playersById[player.playerId] = player;
        _playerAssignments[player.playerId] = team.tournamentTeamId;
      }
    }

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(
      tournamentDetailsProvider(widget.tournamentId),
    );
    final squadAsync = ref.watch(squadDetailProvider(widget.squadId));
    final canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Teams')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: SelectableText(
            'Failed to load teams: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (details) {
          if (!_initialized) {
            _initFromTeams(details.teams);
          }

          if (_teams.isEmpty) {
            return const Center(child: Text('No teams to edit yet.'));
          }

          final players = _playersById.values.toList(growable: false)
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team metadata',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._teams.map((team) => _buildTeamMetaCard(team, canManage)),
                const SizedBox(height: 16),
                Text(
                  'Player assignments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SelectableText(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final selectedTeamId =
                          _playerAssignments[player.playerId];

                      return Card(
                        child: ListTile(
                          title: Text(player.name),
                          subtitle: Text(
                            'Ranking: ${player.ranking.toStringAsFixed(1)}',
                          ),
                          trailing: DropdownButton<String>(
                            value: selectedTeamId,
                            items: _teams
                                .map(
                                  (team) => DropdownMenuItem<String>(
                                    value: team.tournamentTeamId,
                                    child: Text(_teamLabel(team)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: !canManage
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _playerAssignments[player.playerId] =
                                          value;
                                    });
                                  },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: canManage && !_saving ? _save : null,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save teams'),
        ),
      ),
    );
  }

  Widget _buildTeamMetaCard(TournamentTeam team, bool canManage) {
    final nameController = _nameControllers[team.tournamentTeamId]!;
    final colorController = _colorControllers[team.tournamentTeamId]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              enabled: canManage,
              decoration: InputDecoration(
                labelText: 'Name (${_teamLabel(team)})',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: colorController,
              enabled: canManage,
              decoration: const InputDecoration(
                labelText: 'Color hex (optional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final teamToPlayers = <String, List<String>>{
        for (final team in _teams) team.tournamentTeamId: <String>[],
      };

      _playerAssignments.forEach((playerId, teamId) {
        teamToPlayers.putIfAbsent(teamId, () => <String>[]).add(playerId);
      });

      final inputs = <TournamentTeamInput>[];
      for (final team in _teams) {
        final name = _nameControllers[team.tournamentTeamId]!.text.trim();
        final color = _colorControllers[team.tournamentTeamId]!.text.trim();

        inputs.add(
          TournamentTeamInput(
            tournamentTeamId: team.tournamentTeamId,
            name: name.isEmpty ? null : name,
            color: color.isEmpty ? null : color,
            playerIds: teamToPlayers[team.tournamentTeamId] ?? const [],
          ),
        );
      }

      await ref
          .read(updateTournamentTeamsUseCaseProvider)
          .execute(tournamentId: widget.tournamentId, teams: inputs);

      if (!mounted) {
        return;
      }

      ref.invalidate(tournamentDetailsProvider(widget.tournamentId));
      ref.invalidate(squadTournamentsProvider(widget.squadId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament teams updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error is Failure ? error.message : error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

String _teamLabel(TournamentTeam team) {
  final value = team.name?.trim();
  if (value == null || value.isEmpty) {
    return 'Team';
  }
  return value;
}
