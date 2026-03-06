import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_config.dart';
import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/presentation/widgets/draft_draggable_player_tile.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/application/usecases/update_tournament_teams_usecase.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';
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
  final Map<String, String?> _teamColors = {};
  final Map<String, String> _playerAssignments = {};
  final Map<String, Player> _playersById = {};
  static const String _redraftValidationError =
      'Za mało przypisanych graczy, aby ponownie wygenerować drużyny.';

  static const List<String> _teamColorOptions = [
    '#E53935',
    '#D81B60',
    '#8E24AA',
    '#5E35B1',
    '#3949AB',
    '#1E88E5',
    '#039BE5',
    '#00897B',
    '#43A047',
    '#7CB342',
    '#FDD835',
    '#FB8C00',
    '#6D4C41',
    '#546E7A',
  ];

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initFromTeams(List<TournamentTeam> teams) {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }

    _nameControllers.clear();
    _teamColors.clear();
    _playerAssignments.clear();
    _playersById.clear();

    _teams = teams;

    for (var index = 0; index < teams.length; index++) {
      final team = teams[index];

      _nameControllers[team.tournamentTeamId] = TextEditingController(
        text: team.name ?? '',
      );
      _teamColors[team.tournamentTeamId] = team.color;

      for (final player in team.players) {
        _playersById[player.playerId] = player;
        _playerAssignments[player.playerId] = team.tournamentTeamId;
      }
    }

    _initialized = true;
  }

  List<Player> _playersForTeam(String teamId) {
    final players = <Player>[];

    _playerAssignments.forEach((playerId, assignedTeamId) {
      if (assignedTeamId != teamId) {
        return;
      }

      final player = _playersById[playerId];
      if (player != null) {
        players.add(player);
      }
    });

    players.sort((a, b) => b.ranking.compareTo(a.ranking));
    return players;
  }

  void _onPlayerDropped(Object? data, String targetTeamId) {
    if (data is! String) {
      return;
    }

    final playerId = data;
    final currentTeamId = _playerAssignments[playerId];
    if (currentTeamId == null || currentTeamId == targetTeamId) {
      return;
    }

    setState(() {
      _playerAssignments[playerId] = targetTeamId;
      if (_error == _redraftValidationError && _isRedraftInputValid()) {
        _error = null;
      }
    });
  }

  bool _isRedraftInputValid() {
    final teamCount = _teams.length;
    final selectedCount = _playerAssignments.keys.length;
    return teamCount >= 2 && selectedCount >= teamCount;
  }

  Future<void> _pickTeamColor(String teamId) async {
    final current = _teamColors[teamId];
    final theme = Theme.of(context);

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wybierz kolor drużyny'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _teamColorOptions
              .map((hex) {
                final isSelected = hex == current;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(hex),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _parseColor(hex),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _teamColors[teamId] = selected;
    });
  }

  Future<void> _onRedraft() async {
    final teamCount = _teams.length;
    final selectedIds = _playerAssignments.keys.toSet().toList(growable: false);

    if (teamCount < 2 || selectedIds.length < teamCount) {
      setState(() {
        _error = _redraftValidationError;
      });
      return;
    }

    if (_error == _redraftValidationError) {
      setState(() {
        _error = null;
      });
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wygenerować drużyny ponownie?'),
        content: const Text(
          'Wygenerować nowe propozycje drużyn dla tego turnieju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generuj'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    context.pushNamed(
      AppRoute.tournamentDraft.name,
      pathParameters: {
        'squadId': widget.squadId,
        'tournamentId': widget.tournamentId,
      },
      extra: {
        'selectedIds': selectedIds,
        'teamCount': teamCount,
        'draftRules': const <Map<String, dynamic>>[],
      },
    );
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
    final isCompleted =
        detailsAsync.asData?.value.tournament.status ==
        TournamentStatus.completed;
    final canEditTeams = canManage && !isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drużyny turniejowe'),
        actions: [
          if (canEditTeams)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _saving || !_initialized ? null : _onRedraft,
                icon: const Icon(Icons.refresh),
                label: const Text('Generuj ponownie'),
              ),
            ),
          if (canEditTeams)
            IconButton(
              tooltip: 'Zapisz drużyny',
              onPressed: _saving || !_initialized ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: SelectableText(
            'Nie udało się wczytać drużyn: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (details) {
          final canEditTeams =
              canManage &&
              details.tournament.status != TournamentStatus.completed;

          if (!_initialized) {
            _initFromTeams(details.teams);
          }

          if (_teams.isEmpty) {
            return const Center(child: Text('Brak drużyn do edycji.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Drużyny',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  canEditTeams
                      ? 'Przeciągaj graczy między drużynami, aby zmienić składy.'
                      : details.tournament.status == TournamentStatus.completed
                      ? 'Turniej zakończony. Składy drużyn są tylko do odczytu.'
                      : 'Składy drużyn są tylko do odczytu.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SelectableText.rich(
                      TextSpan(
                        text: _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact =
                          constraints.maxWidth < AppConfig.compactWidth;
                      const spacing = 12.0;
                      const minTileWidth = 250.0;
                      final maxColumns = _teams.length.clamp(1, 4);
                      final columns = isCompact
                          ? 1
                          : ((constraints.maxWidth + spacing) /
                                    (minTileWidth + spacing))
                                .floor()
                                .clamp(1, maxColumns);
                      final tileWidth = isCompact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - (columns - 1) * spacing) /
                                columns;

                      final cards = [
                        for (var index = 0; index < _teams.length; index++)
                          SizedBox(
                            width: tileWidth,
                            child: _TeamEditorCard(
                              teamIndex: index,
                              players: _playersForTeam(
                                _teams[index].tournamentTeamId,
                              ),
                              nameController:
                                  _nameControllers[_teams[index]
                                      .tournamentTeamId]!,
                              colorHex:
                                  _teamColors[_teams[index].tournamentTeamId],
                              canManage: canEditTeams,
                              compact: isCompact,
                              onPickColor: canEditTeams
                                  ? () => _pickTeamColor(
                                      _teams[index].tournamentTeamId,
                                    )
                                  : null,
                              onAcceptPlayer: canEditTeams
                                  ? (data) => _onPlayerDropped(
                                      data,
                                      _teams[index].tournamentTeamId,
                                    )
                                  : null,
                              onOpenPlayer: (playerId) {
                                context.pushNamed(
                                  AppRoute.playerDetails.name,
                                  pathParameters: {
                                    'squadId': widget.squadId,
                                    'playerId': playerId,
                                  },
                                );
                              },
                            ),
                          ),
                      ];

                      if (isCompact) {
                        return ListView.separated(
                          itemCount: cards.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => cards[index],
                        );
                      }

                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: cards,
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
        final teamId = team.tournamentTeamId;
        final name = _nameControllers[teamId]!.text.trim();
        final color = (_teamColors[teamId] ?? '').trim();

        inputs.add(
          TournamentTeamInput(
            tournamentTeamId: teamId,
            name: name.isEmpty ? null : name,
            color: color.isEmpty ? null : color,
            playerIds: teamToPlayers[teamId] ?? const [],
          ),
        );
      }

      await ref
          .read(updateTournamentTeamsUseCaseProvider)
          .execute(tournamentId: widget.tournamentId, teams: inputs);

      if (!mounted) {
        return;
      }

      setState(() {
        _initialized = false;
      });

      ref.invalidate(tournamentDetailsProvider(widget.tournamentId));
      ref.invalidate(squadTournamentsProvider(widget.squadId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drużyny turnieju zostały zapisane.')),
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

class _TeamEditorCard extends StatelessWidget {
  const _TeamEditorCard({
    required this.teamIndex,
    required this.players,
    required this.nameController,
    required this.colorHex,
    required this.canManage,
    required this.compact,
    required this.onPickColor,
    required this.onAcceptPlayer,
    required this.onOpenPlayer,
  });

  final int teamIndex;
  final List<Player> players;
  final TextEditingController nameController;
  final String? colorHex;
  final bool canManage;
  final bool compact;
  final VoidCallback? onPickColor;
  final ValueChanged<Object?>? onAcceptPlayer;
  final ValueChanged<String> onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: onAcceptPlayer == null
          ? null
          : (details) {
              final data = details.data;
              if (data is! String) {
                return false;
              }

              return !players.any((player) => player.playerId == data);
            },
      onAcceptWithDetails: onAcceptPlayer == null
          ? null
          : (details) => onAcceptPlayer!(details.data),
      builder: (context, candidateData, rejectedData) {
        final theme = Theme.of(context);
        final teamColor = _parseColor(colorHex);
        final rankingTotal = _totalRanking(players);
        final isHighlighted = candidateData.isNotEmpty;

        return Card(
          shape: isHighlighted
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary, width: 2),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TeamColorBox(
                      color: teamColor,
                      editable: canManage,
                      size: compact ? 20 : 24,
                      onTap: onPickColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: canManage
                          ? TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Drużyna ${teamIndex + 1}',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                            )
                          : Text(
                              _displayTeamName(
                                nameController.text,
                                'Drużyna ${teamIndex + 1}',
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gracze: ${players.length} | Ranking: ${rankingTotal.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 18),
                if (players.isEmpty)
                  Container(
                    height: compact ? 50 : 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Przeciągnij tu graczy'),
                  )
                else
                  ...players.map(
                    (player) => DraftDraggablePlayerTile(
                      player: player,
                      trailing: canManage
                          ? const Icon(Icons.drag_indicator)
                          : const SizedBox.shrink(),
                      compact: compact,
                      dragData: canManage ? player.playerId : null,
                      onTap: canManage
                          ? null
                          : () => onOpenPlayer(player.playerId),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeamColorBox extends StatelessWidget {
  const _TeamColorBox({
    required this.color,
    required this.editable,
    required this.size,
    required this.onTap,
  });

  final Color color;
  final bool editable;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: editable
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withValues(alpha: 0.5),
          width: editable ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );

    if (!editable || onTap == null) {
      return box;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: box,
    );
  }
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

String _displayTeamName(String? name, String fallback) {
  final value = name?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

double _totalRanking(List<Player> players) {
  var total = 0.0;
  for (final player in players) {
    total += player.ranking;
  }
  return total;
}
