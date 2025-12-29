import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/presentation/controllers/match_details_notifier.dart';
import 'package:app/features/matches/presentation/widgets/match_player_tile.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';

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

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
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
    });
  }

  Future<void> _saveChanges() async {
    // Save Score
    final homeScoreText = _homeScoreController.text.trim();
    final awayScoreText = _awayScoreController.text.trim();

    if (homeScoreText.isNotEmpty && awayScoreText.isNotEmpty) {
      final home = int.tryParse(homeScoreText);
      final away = int.tryParse(awayScoreText);

      if (home == null || away == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid scores')),
        );
        return;
      }
      await ref
          .read(matchDetailsProvider(widget.matchId).notifier)
          .updateScore(widget.squadId, home, away);
    }

    // Save Teams
    final homeIds = _homePlayers.map((p) => p.playerId).toList();
    final awayIds = _awayPlayers.map((p) => p.playerId).toList();

    await ref
        .read(matchDetailsProvider(widget.matchId).notifier)
        .updateTeams(homeIds, awayIds);

    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
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

    // Navigate to Draft Selection with pre-selected players
    // Note: DraftSelectionPage needs to support this.
    // For now passing as extra, assuming implementation exists or will exist.
    context.pushNamed(
      AppRoute.draftSelection.name,
      pathParameters: {'squadId': widget.squadId},
      extra: {
        'selectedIds': selectedIds,
        'matchId': widget.matchId, // Pass matchId to indicate update mode
      },
    );
  }

  void _onPlayerDropped(Object? data, String targetSide) {
    if (data is! String) return;
    final playerId = data;

    // Find player in current lists
    Player? player;
    try {
      player = _homePlayers.firstWhere((p) => p.playerId == playerId);
    } catch (_) {
      try {
        player = _awayPlayers.firstWhere((p) => p.playerId == playerId);
      } catch (_) {
        return;
      }
    }

    if (player == null) return;

    setState(() {
      _homePlayers.removeWhere((p) => p.playerId == playerId);
      _awayPlayers.removeWhere((p) => p.playerId == playerId);

      if (targetSide == 'home') {
        _homePlayers.add(player!);
      } else {
        _awayPlayers.add(player!);
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
        data: (match) => _buildContent(context, match),
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
          if (_isEditing) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _deleteMatch,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.delete),
              label: const Text('Delete Match'),
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
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamSection(
                  context,
                  _isEditing ? _awayPlayers : (match.awayTeam?.players ?? []),
                  match.awayTeam?.name ?? 'Away',
                  'away',
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
  ) {
    final list = Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        ...players.map(
          (player) => MatchPlayerTile(
            player: player,
            trailing: const SizedBox.shrink(),
            dragData: _isEditing ? player.playerId : null,
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
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
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
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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
}
