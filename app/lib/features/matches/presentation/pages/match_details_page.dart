import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/utils/team_ranking.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/presentation/controllers/match_details_notifier.dart';
import 'package:app/features/matches/presentation/widgets/match_player_tile.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/matches/presentation/controllers/squad_matches_notifier.dart';

class MatchDetailsPage extends ConsumerStatefulWidget {
  final String squadId;
  final String matchId;

  const MatchDetailsPage({
    super.key,
    required this.squadId,
    required this.matchId,
  });

  @override
  ConsumerState<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends ConsumerState<MatchDetailsPage> {
  bool _isEditing = false;
  final TextEditingController _homeScoreController = TextEditingController();
  final TextEditingController _awayScoreController = TextEditingController();
  final TextEditingController _homeTeamNameController = TextEditingController();
  final TextEditingController _awayTeamNameController = TextEditingController();

  List<Player> _homePlayers = [];
  List<Player> _awayPlayers = [];
  bool _isDraggingPlayer = false;

  bool _isAddPlayerOpen = false;
  final TextEditingController _playerSearchController = TextEditingController();
  List<Player> _squadPlayers = [];
  String? _homeTeamColorHex;
  String? _awayTeamColorHex;
  String? _initialHomeTeamName;
  String? _initialAwayTeamName;
  String? _initialHomeTeamColorHex;
  String? _initialAwayTeamColorHex;

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
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _homeTeamNameController.dispose();
    _awayTeamNameController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MatchDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _isEditing = false;
      _isAddPlayerOpen = false;
      _homePlayers = [];
      _awayPlayers = [];
      _homeTeamNameController.clear();
      _awayTeamNameController.clear();
      _homeTeamColorHex = null;
      _awayTeamColorHex = null;
      _initialHomeTeamName = null;
      _initialAwayTeamName = null;
      _initialHomeTeamColorHex = null;
      _initialAwayTeamColorHex = null;
      ref.invalidate(matchDetailsProvider(widget.matchId));
    }
  }

  void _enterEditMode(Match match) {
    if (match.homeTeam == null || match.awayTeam == null) return;
    setState(() {
      _isEditing = true;
      _homeScoreController.text = match.homeScore?.toString() ?? '';
      _awayScoreController.text = match.awayScore?.toString() ?? '';
      _homePlayers = List.from(match.homeTeam!.players);
      _awayPlayers = List.from(match.awayTeam!.players);
      _homeTeamNameController.text = match.homeTeam?.name ?? '';
      _awayTeamNameController.text = match.awayTeam?.name ?? '';
      _homeTeamColorHex = match.homeTeam?.color;
      _awayTeamColorHex = match.awayTeam?.color;
      _initialHomeTeamName = match.homeTeam?.name ?? '';
      _initialAwayTeamName = match.awayTeam?.name ?? '';
      _initialHomeTeamColorHex = match.homeTeam?.color;
      _initialAwayTeamColorHex = match.awayTeam?.color;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _homePlayers.clear();
      _awayPlayers.clear();
      _isAddPlayerOpen = false;
      _isDraggingPlayer = false;
      _homeTeamNameController.clear();
      _awayTeamNameController.clear();
      _homeTeamColorHex = null;
      _awayTeamColorHex = null;
      _initialHomeTeamName = null;
      _initialAwayTeamName = null;
      _initialHomeTeamColorHex = null;
      _initialAwayTeamColorHex = null;
    });
  }

  Future<void> _saveChanges(Match match) async {
    final homeTeam = match.homeTeam;
    final awayTeam = match.awayTeam;
    if (homeTeam == null || awayTeam == null) return;

    final nextHomeName = _homeTeamNameController.text.trim();
    final nextAwayName = _awayTeamNameController.text.trim();

    final homeNameChanged = nextHomeName != (_initialHomeTeamName ?? '');
    final awayNameChanged = nextAwayName != (_initialAwayTeamName ?? '');

    final homeColorChanged = _homeTeamColorHex != _initialHomeTeamColorHex;
    final awayColorChanged = _awayTeamColorHex != _initialAwayTeamColorHex;

    if (homeNameChanged ||
        awayNameChanged ||
        homeColorChanged ||
        awayColorChanged) {
      await ref
          .read(matchDetailsProvider(widget.matchId).notifier)
          .updateTeamsMeta(
            homeTeamId: homeTeam.teamId,
            awayTeamId: awayTeam.teamId,
            homeName: homeNameChanged ? nextHomeName : null,
            awayName: awayNameChanged ? nextAwayName : null,
            homeColor: homeColorChanged ? _homeTeamColorHex : null,
            awayColor: awayColorChanged ? _awayTeamColorHex : null,
          );
    }

    // 1. Save Teams FIRST
    final homeIds = _homePlayers.map((p) => p.playerId).toList();
    final awayIds = _awayPlayers.map((p) => p.playerId).toList();

    final homePlayersChanged = !_arePlayerIdsEqual(
      _homePlayers,
      homeTeam.players,
    );
    final awayPlayersChanged = !_arePlayerIdsEqual(
      _awayPlayers,
      awayTeam.players,
    );

    if (homePlayersChanged || awayPlayersChanged) {
      await ref
          .read(matchDetailsProvider(widget.matchId).notifier)
          .updateTeams(homeIds, awayIds);
    }

    // 2. Save Score THEN
    final homeScoreText = _homeScoreController.text.trim();
    final awayScoreText = _awayScoreController.text.trim();

    if (homeScoreText.isNotEmpty && awayScoreText.isNotEmpty) {
      final home = int.tryParse(homeScoreText);
      final away = int.tryParse(awayScoreText);

      if (home == null || away == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter valid scores')),
          );
        }
        return;
      }
      await ref
          .read(matchDetailsProvider(widget.matchId).notifier)
          .updateScore(widget.squadId, home, away);
    }

    if (mounted) {
      setState(() {
        _isEditing = false;
        _isAddPlayerOpen = false;
        _isDraggingPlayer = false;
      });
    }

    // Ensure matches list refreshes when user goes back.
    ref.invalidate(squadMatchesProvider(widget.squadId));
  }

  Future<void> _deleteMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match?'),
        content: const Text(
          'This will revert all ranking changes associated with this match. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(matchDetailsProvider(widget.matchId).notifier).deleteMatch();

    if (mounted) {
      ref.invalidate(squadMatchesProvider(widget.squadId));
      context.pop(); // Go back to list
    }
  }

  Future<void> _onRematch() async {
    final newMatch = await ref
        .read(matchDetailsProvider(widget.matchId).notifier)
        .rematch();
    if (mounted) {
      context.pushNamed(
        AppRoute.matchDetails.name,
        pathParameters: {
          'squadId': widget.squadId,
          'matchId': newMatch.matchId,
        },
      );
    }
  }

  Future<void> _onRedraft(Match match) async {
    if (match.homeTeam == null || match.awayTeam == null) return;
    final allPlayers = [...match.homeTeam!.players, ...match.awayTeam!.players];
    final selectedIds = allPlayers.map((p) => p.playerId).toList();

    context.pushNamed(
      AppRoute.draftSelection.name,
      pathParameters: {'squadId': widget.squadId},
      extra: {'selectedIds': selectedIds, 'matchId': widget.matchId},
    );
  }

  void _onPlayerDropped(Object? data, String targetSide) {
    if (data is! String) return;
    final playerId = data;

    // Find player in current lists
    Player player;
    try {
      player = _homePlayers.firstWhere((p) => p.playerId == playerId);
    } catch (_) {
      try {
        player = _awayPlayers.firstWhere((p) => p.playerId == playerId);
      } catch (_) {
        // If the player is not currently in teams, we might be dragging from add-player panel.
        final fromPool = _squadPlayers.where((p) => p.playerId == playerId);
        if (fromPool.isEmpty) return;
        player = fromPool.first;
      }
    }

    setState(() {
      _homePlayers.removeWhere((p) => p.playerId == playerId);
      _awayPlayers.removeWhere((p) => p.playerId == playerId);

      if (targetSide == 'home') {
        _homePlayers.add(player);
      } else {
        _awayPlayers.add(player);
      }
    });
  }

  void _removePlayerFromMatch(Object? data) {
    if (data is! String) return;
    final playerId = data;
    setState(() {
      _homePlayers.removeWhere((p) => p.playerId == playerId);
      _awayPlayers.removeWhere((p) => p.playerId == playerId);
    });
  }

  Future<void> _toggleAddPlayer() async {
    final next = !_isAddPlayerOpen;
    setState(() {
      _isAddPlayerOpen = next;
      _playerSearchController.clear();
    });

    if (!next) return;
    if (_squadPlayers.isNotEmpty) return;

    final players = await ref
        .read(getSquadPlayersUseCaseProvider)
        .execute(squadId: widget.squadId);
    if (!mounted) return;
    setState(() {
      _squadPlayers = players;
    });
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _displayTeamName(String? name, String fallback) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  bool _arePlayerIdsEqual(List<Player> a, List<Player> b) {
    if (a.length != b.length) return false;
    final aIds = {for (final p in a) p.playerId};
    final bIds = {for (final p in b) p.playerId};
    return aIds.length == bIds.length && aIds.containsAll(bIds);
  }

  Future<void> _pickTeamColor(String side) async {
    final current = side == 'home' ? _homeTeamColorHex : _awayTeamColorHex;
    final theme = Theme.of(context);
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select team color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _teamColorOptions.map((hex) {
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
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      if (side == 'home') {
        _homeTeamColorHex = selected;
      } else {
        _awayTeamColorHex = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailsProvider(widget.matchId));
    final squadAsync = ref.watch(squadDetailProvider(widget.squadId));

    final canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        actions: [
          if (canManage && matchAsync.hasValue) ...[
            if (_isEditing) ...[
              IconButton(
                icon: Icon(
                  _isAddPlayerOpen ? Icons.person_off : Icons.person_add,
                ),
                onPressed: _toggleAddPlayer,
                tooltip: _isAddPlayerOpen ? 'Close add player' : 'Add player',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveChanges(matchAsync.value!),
                tooltip: 'Save',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelEdit,
                tooltip: 'Cancel',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteMatch,
                tooltip: 'Delete Match',
                color: Colors.red,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _onRedraft(matchAsync.value!),
                tooltip: 'Redraft',
              ),
              IconButton(
                icon: const Icon(Icons.replay),
                onPressed: _onRematch,
                tooltip: 'Rematch',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _enterEditMode(matchAsync.value!),
                tooltip: 'Edit',
              ),
            ],
          ],
        ],
      ),
      body: matchAsync.when(
        data: (match) => Stack(
          children: [
            _buildContent(context, match),
            if (_isEditing && _isDraggingPlayer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _RemoveDropZone(onRemove: _removePlayerFromMatch),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: SelectableText.rich(
            TextSpan(
              text: 'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Match match) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final scoreBoard = _isEditing
        ? _buildEditScoreBoard()
        : _buildScoreBoard(match);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            dateFormat.format(match.createdAt.toLocal()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_isEditing && _isAddPlayerOpen) ...[
            _AddPlayerPanel(
              players: _availableSquadPlayers(),
              searchController: _playerSearchController,
              onQueryChanged: (_) => setState(() {}),
              onDragStarted: () => setState(() => _isDraggingPlayer = true),
              onDragEnd: () => setState(() => _isDraggingPlayer = false),
            ),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final homeSection = _buildTeamSection(
                context,
                _isEditing ? _homePlayers : (match.homeTeam?.players ?? []),
                match.homeTeam?.name,
                'Home',
                'home',
                _isEditing ? _homeTeamColorHex : match.homeTeam?.color,
                opponentCount: _isEditing
                    ? _awayPlayers.length
                    : (match.awayTeam?.players.length ?? 0),
                nameController: _isEditing ? _homeTeamNameController : null,
              );
              final awaySection = _buildTeamSection(
                context,
                _isEditing ? _awayPlayers : (match.awayTeam?.players ?? []),
                match.awayTeam?.name,
                'Away',
                'away',
                _isEditing ? _awayTeamColorHex : match.awayTeam?.color,
                opponentCount: _isEditing
                    ? _homePlayers.length
                    : (match.homeTeam?.players.length ?? 0),
                nameController: _isEditing ? _awayTeamNameController : null,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    homeSection,
                    const SizedBox(height: 16),
                    Center(child: scoreBoard),
                    const SizedBox(height: 16),
                    awaySection,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: homeSection),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 220,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: scoreBoard,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: awaySection),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(Match match) {
    final hasScore = match.homeScore != null && match.awayScore != null;
    final homeScore = hasScore ? match.homeScore.toString() : '-';
    final awayScore = hasScore ? match.awayScore.toString() : '-';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          homeScore,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(':', style: TextStyle(fontSize: 48)),
        ),
        Text(
          awayScore,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEditScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            controller: _homeScoreController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Home',
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(':', style: TextStyle(fontSize: 48)),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _awayScoreController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Away',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    List<Player> players,
    String? teamName,
    String fallbackLabel,
    String side,
    String? colorHex, {
    required int opponentCount,
    TextEditingController? nameController,
  }) {
    final teamColor = _parseColor(colorHex);
    final theme = Theme.of(context);
    final sortedPlayers = [...players]
      ..sort((a, b) => b.ranking.compareTo(a.ranking));

    // Compute ranking
    double totalRanking = 0;
    for (final p in players) {
      totalRanking += p.ranking;
    }
    // Assume playWithSubstitute=true if sizes differ
    final playWithSubstitute = players.length != opponentCount;

    final effective = effectiveTeamRanking(
      totalRanking: totalRanking,
      teamSize: players.length,
      opponentTeamSize: opponentCount,
      playWithSubstitute: playWithSubstitute,
    );

    final list = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isEditing
                ? GestureDetector(
                    onTap: () => _pickTeamColor(side),
                    child: Tooltip(
                      message: 'Change color',
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: teamColor,
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: teamColor,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
            const SizedBox(width: 8),
            if (_isEditing && nameController != null)
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextField(
                    controller: nameController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: fallbackLabel,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                ),
              )
            else
              Text(
                _displayTeamName(teamName, fallbackLabel),
                style: theme.textTheme.titleLarge,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Rating: ${effective.toStringAsFixed(1)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Divider(),
        ...sortedPlayers.map(
          (player) => MatchPlayerTile(
            player: player,
            trailing: const SizedBox.shrink(),
            dragData: _isEditing ? player.playerId : null,
            onDragStarted: _isEditing
                ? () => setState(() => _isDraggingPlayer = true)
                : null,
            onDragEnd: _isEditing
                ? () => setState(() => _isDraggingPlayer = false)
                : null,
            onTap: !_isEditing
                ? () {
                    context.pushNamed(
                      AppRoute.playerDetails.name,
                      pathParameters: {
                        'squadId': widget.squadId,
                        'playerId': player.playerId,
                      },
                    );
                  }
                : null,
          ),
        ),
        if (_isEditing && players.isEmpty)
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Drag players here'),
          ),
      ],
    );

    if (_isEditing) {
      return DragTarget<Object>(
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: list,
          );
        },
        onAcceptWithDetails: (details) => _onPlayerDropped(details.data, side),
      );
    }

    return list;
  }

  List<Player> _availableSquadPlayers() {
    final existingIds = <String>{
      for (final p in _homePlayers) p.playerId,
      for (final p in _awayPlayers) p.playerId,
    };

    final q = _playerSearchController.text.trim().toLowerCase();
    return _squadPlayers
        .where((p) => !existingIds.contains(p.playerId))
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList(growable: false);
  }
}

class _RemoveDropZone extends StatelessWidget {
  const _RemoveDropZone({required this.onRemove});

  final ValueChanged<Object?> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) => details.data is String,
      onAcceptWithDetails: (details) => onRemove(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        return Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: theme.colorScheme.error.withValues(
            alpha: isHighlighted ? 0.25 : 0.18,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close, color: theme.colorScheme.error, size: 28),
              const SizedBox(width: 8),
              Text(
                'Drag here to remove',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddPlayerPanel extends StatelessWidget {
  const _AddPlayerPanel({
    required this.players,
    required this.searchController,
    required this.onQueryChanged,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final List<Player> players;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add player', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.none,
              onChanged: onQueryChanged,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: players.isEmpty
                  ? const Center(child: Text('No available players.'))
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final p = players[index];
                        return MatchPlayerTile(
                          player: p,
                          trailing: const Icon(Icons.drag_indicator),
                          dragData: p.playerId,
                          onDragStarted: onDragStarted,
                          onDragEnd: onDragEnd,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
