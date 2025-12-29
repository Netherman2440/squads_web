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

  List<Player> _homePlayers = [];
  List<Player> _awayPlayers = [];
  bool _isDraggingPlayer = false;

  bool _isAddPlayerOpen = false;
  final TextEditingController _playerSearchController = TextEditingController();
  List<Player> _squadPlayers = [];

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
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
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _homePlayers.clear();
      _awayPlayers.clear();
      _isAddPlayerOpen = false;
      _isDraggingPlayer = false;
    });
  }

  Future<void> _saveChanges() async {
    // 1. Save Teams FIRST
    final homeIds = _homePlayers.map((p) => p.playerId).toList();
    final awayIds = _awayPlayers.map((p) => p.playerId).toList();

    await ref
        .read(matchDetailsProvider(widget.matchId).notifier)
        .updateTeams(homeIds, awayIds);

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
                onPressed: _saveChanges,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            dateFormat.format(match.createdAt.toLocal()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_isEditing) _buildEditScoreBoard() else _buildScoreBoard(match),
          if (_isEditing && _isAddPlayerOpen) ...[
            const SizedBox(height: 16),
            _AddPlayerPanel(
              players: _availableSquadPlayers(),
              searchController: _playerSearchController,
              onQueryChanged: (_) => setState(() {}),
              onDragStarted: () => setState(() => _isDraggingPlayer = true),
              onDragEnd: () => setState(() => _isDraggingPlayer = false),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTeamSection(
                  context,
                  _isEditing ? _homePlayers : (match.homeTeam?.players ?? []),
                  match.homeTeam?.name ?? 'Home',
                  'home',
                  match.homeTeam?.color,
                  opponentCount: _isEditing
                      ? _awayPlayers.length
                      : (match.awayTeam?.players.length ?? 0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamSection(
                  context,
                  _isEditing ? _awayPlayers : (match.awayTeam?.players ?? []),
                  match.awayTeam?.name ?? 'Away',
                  'away',
                  match.awayTeam?.color,
                  opponentCount: _isEditing
                      ? _homePlayers.length
                      : (match.homeTeam?.players.length ?? 0),
                ),
              ),
            ],
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
    String label,
    String side,
    String? colorHex, {
    required int opponentCount,
  }) {
    final teamColor = _parseColor(colorHex);
    final theme = Theme.of(context);

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
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: teamColor,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.titleLarge),
          ],
        ),
        Text(
          'Rating: ${effective.toStringAsFixed(1)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Divider(),
        ...players.map(
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
                    context.goNamed(
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
