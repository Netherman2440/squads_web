import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/utils/team_ranking.dart';
import 'package:app/features/matches/application/dto/match_details_dto.dart';
import 'package:app/features/matches/application/dto/player_dto.dart';
import 'package:app/features/matches/presentation/controllers/match_details_notifier.dart';
import 'package:app/features/matches/presentation/widgets/match_player_tile.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/matches/presentation/controllers/squad_matches_notifier.dart';
import 'package:app/core/app_config.dart';
import 'package:app/core/widgets/probability_slider.dart';

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

  List<PlayerDto> _homePlayers = [];
  List<PlayerDto> _awayPlayers = [];
  bool _isDraggingPlayer = false;

  bool _isAddPlayerOpen = false;
  final TextEditingController _playerSearchController = TextEditingController();
  List<PlayerDto> _squadPlayers = [];
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

  void _enterEditMode(MatchDetailsDto match) {
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

  Future<void> _saveChanges(MatchDetailsDto match) async {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Utworzyć rewanż?'),
        content: const Text('Czy chcesz utworzyć rewanż?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Utwórz rewanż'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

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

  Future<void> _onRedraft(MatchDetailsDto match) async {
    if (match.homeTeam == null || match.awayTeam == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wylosować składy ponownie?'),
        content: const Text('Czy chcesz jeszcze raz wylosować składy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Wylosuj'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final allPlayers = [...match.homeTeam!.players, ...match.awayTeam!.players];
    final selectedIds = allPlayers.map((p) => p.playerId).toList();

    context.pushNamed(
      AppRoute.draftCreate.name,
      pathParameters: {'squadId': widget.squadId},
      extra: {'selectedIds': selectedIds, 'matchId': widget.matchId},
    );
  }

  void _onPlayerDropped(Object? data, String targetSide) {
    if (data is! String) return;
    final playerId = data;

    // Find player in current lists
    PlayerDto player;
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
      _squadPlayers = players.map(PlayerDto.fromDomain).toList();
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

  bool _arePlayerIdsEqual(List<PlayerDto> a, List<PlayerDto> b) {
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
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                tooltip: 'Wróć do meczów',
                onPressed: () {
                  context.goNamed(
                    AppRoute.matches.name,
                    pathParameters: {'squadId': widget.squadId},
                  );
                },
                icon: const Icon(Icons.arrow_back),
              ),
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
            _buildContent(context, match, canManage: canManage),
            if (_isEditing && _isDraggingPlayer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _RemoveDropZone(onRemove: _removePlayerFromMatch),
                ),
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

  Widget _buildContent(
    BuildContext context,
    MatchDetailsDto match, {
    required bool canManage,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final bottomInset = _isEditing && _isDraggingPlayer ? 84.0 : 0.0;
    final hasScore = match.homeScore != null && match.awayScore != null;
    final hasTeamAssignments =
        (match.homeTeam?.players.isNotEmpty ?? false) &&
        (match.awayTeam?.players.isNotEmpty ?? false);
    final selectedIds = <String>{
      for (final player in match.homeTeam?.players ?? const []) player.playerId,
      for (final player in match.awayTeam?.players ?? const []) player.playerId,
    }.toList(growable: false);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        children: [
          if (canManage && !_isEditing)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (!hasScore && hasTeamAssignments)
                    TextButton(
                      onPressed: () => _onRedraft(match),
                      child: const Text('Wylosuj jeszcze raz'),
                    ),
                  if (!hasTeamAssignments)
                    TextButton(
                      onPressed: () {
                        context.pushNamed(
                          AppRoute.draftCreate.name,
                          pathParameters: {'squadId': widget.squadId},
                          extra: {
                            'selectedIds': selectedIds,
                            'matchId': widget.matchId,
                          },
                        );
                      },
                      child: const Text('Wybierz drużyny'),
                    ),
                  TextButton(
                    onPressed: () {
                      context.pushNamed(
                        AppRoute.matchDraft.name,
                        pathParameters: {
                          'squadId': widget.squadId,
                          'matchId': widget.matchId,
                        },
                      );
                    },
                    child: const Text('Podgląd draftu'),
                  ),
                  TextButton(
                    onPressed: _onRematch,
                    child: const Text('Rewanż'),
                  ),
                ],
              ),
            ),
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
              final isCompact = constraints.maxWidth < AppConfig.compactWidth;
              final scoreBoard = _isEditing
                  ? _buildEditScoreBoard(compact: isCompact)
                  : _buildScoreBoard(match, compact: isCompact);
              final homeSection = _buildTeamSection(
                context,
                _isEditing
                    ? _homePlayers
                    : (match.homeTeam?.players ?? const <PlayerDto>[]),
                match.homeTeam?.name,
                'Home',
                'home',
                _isEditing ? _homeTeamColorHex : match.homeTeam?.color,
                opponentCount: _isEditing
                    ? _awayPlayers.length
                    : (match.awayTeam?.players.length ?? 0),
                nameController: _isEditing ? _homeTeamNameController : null,
                compact: isCompact,
              );
              final awaySection = _buildTeamSection(
                context,
                _isEditing
                    ? _awayPlayers
                    : (match.awayTeam?.players ?? const <PlayerDto>[]),
                match.awayTeam?.name,
                'Away',
                'away',
                _isEditing ? _awayTeamColorHex : match.awayTeam?.color,
                opponentCount: _isEditing
                    ? _homePlayers.length
                    : (match.homeTeam?.players.length ?? 0),
                nameController: _isEditing ? _awayTeamNameController : null,
                compact: isCompact,
              );

              final gap = isCompact ? 8.0 : 16.0;
              final scoreBoardWidth = isCompact ? 140.0 : 220.0;

              if (isCompact) {
                final homePlayers = _isEditing
                    ? _homePlayers
                    : (match.homeTeam?.players ?? const <PlayerDto>[]);
                final awayPlayers = _isEditing
                    ? _awayPlayers
                    : (match.awayTeam?.players ?? const <PlayerDto>[]);
                final homeOpponentCount = _isEditing
                    ? _awayPlayers.length
                    : awayPlayers.length;
                final awayOpponentCount = _isEditing
                    ? _homePlayers.length
                    : homePlayers.length;
                final homeRating = _effectiveTeamRating(
                  homePlayers,
                  homeOpponentCount,
                );
                final awayRating = _effectiveTeamRating(
                  awayPlayers,
                  awayOpponentCount,
                );

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildCompactTeamHeader(
                            teamName: match.homeTeam?.name,
                            fallbackLabel: 'Home',
                            colorHex: _isEditing
                                ? _homeTeamColorHex
                                : match.homeTeam?.color,
                            nameController: _isEditing
                                ? _homeTeamNameController
                                : null,
                            rating: homeRating,
                            alignEnd: false,
                            onPickColor: _isEditing
                                ? () => _pickTeamColor('home')
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: scoreBoardWidth,
                          child: Align(
                            alignment: Alignment.center,
                            child: scoreBoard,
                          ),
                        ),
                        Expanded(
                          child: _buildCompactTeamHeader(
                            teamName: match.awayTeam?.name,
                            fallbackLabel: 'Away',
                            colorHex: _isEditing
                                ? _awayTeamColorHex
                                : match.awayTeam?.color,
                            nameController: _isEditing
                                ? _awayTeamNameController
                                : null,
                            rating: awayRating,
                            alignEnd: true,
                            onPickColor: _isEditing
                                ? () => _pickTeamColor('away')
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTeamSection(
                            context,
                            homePlayers,
                            match.homeTeam?.name,
                            'Home',
                            'home',
                            _isEditing
                                ? _homeTeamColorHex
                                : match.homeTeam?.color,
                            opponentCount: homeOpponentCount,
                            nameController: _isEditing
                                ? _homeTeamNameController
                                : null,
                            compact: true,
                            showHeader: false,
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: _buildTeamSection(
                            context,
                            awayPlayers,
                            match.awayTeam?.name,
                            'Away',
                            'away',
                            _isEditing
                                ? _awayTeamColorHex
                                : match.awayTeam?.color,
                            opponentCount: awayOpponentCount,
                            nameController: _isEditing
                                ? _awayTeamNameController
                                : null,
                            compact: true,
                            showHeader: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: homeSection),
                  SizedBox(width: gap),
                  SizedBox(
                    width: scoreBoardWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: scoreBoard,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(child: awaySection),
                ],
              );
            },
          ),
          if (!_isEditing && match.homeWinProbability != null) ...[
            const SizedBox(height: 24),
            ProbabilitySlider(
              title: 'Win probability',
              homeColor: _parseColor(match.homeTeam?.color),
              awayColor: _parseColor(match.awayTeam?.color),
              homeProbability: match.homeWinProbability!,
              infoText:
                  'Estimated from historical head-to-head results between '
                  'players in this squad.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBoard(MatchDetailsDto match, {required bool compact}) {
    final hasScore = match.homeScore != null && match.awayScore != null;
    final homeScore = hasScore ? match.homeScore.toString() : '-';
    final awayScore = hasScore ? match.awayScore.toString() : '-';
    final fontSize = compact ? 32.0 : 48.0;
    final separatorSize = compact ? 32.0 : 48.0;
    final padding = compact ? 8.0 : 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          homeScore,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(':', style: TextStyle(fontSize: separatorSize)),
        ),
        Text(
          awayScore,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEditScoreBoard({required bool compact}) {
    final fontSize = compact ? 24.0 : 32.0;
    final width = compact ? 56.0 : 80.0;
    final padding = compact ? 8.0 : 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: width,
          child: TextField(
            controller: _homeScoreController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Home',
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(':', style: TextStyle(fontSize: fontSize + 8)),
        ),
        SizedBox(
          width: width,
          child: TextField(
            controller: _awayScoreController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Away',
            ),
          ),
        ),
      ],
    );
  }

  double _effectiveTeamRating(List<PlayerDto> players, int opponentCount) {
    double totalRanking = 0;
    for (final p in players) {
      totalRanking += p.ranking;
    }
    final playWithSubstitute = players.length != opponentCount;
    return effectiveTeamRanking(
      totalRanking: totalRanking,
      teamSize: players.length,
      opponentTeamSize: opponentCount,
      playWithSubstitute: playWithSubstitute,
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    List<PlayerDto> players,
    String? teamName,
    String fallbackLabel,
    String side,
    String? colorHex, {
    required int opponentCount,
    TextEditingController? nameController,
    required bool compact,
    bool showHeader = true,
  }) {
    final teamColor = _parseColor(colorHex);
    final theme = Theme.of(context);
    final sortedPlayers = [...players]
      ..sort((a, b) => b.ranking.compareTo(a.ranking));

    final effective = _effectiveTeamRating(players, opponentCount);

    final list = Column(
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isEditing
                  ? GestureDetector(
                      onTap: () => _pickTeamColor(side),
                      child: Tooltip(
                        message: 'Change color',
                        child: Container(
                          width: compact ? 24 : 32,
                          height: compact ? 24 : 32,
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
                      width: compact ? 24 : 32,
                      height: compact ? 24 : 32,
                      decoration: BoxDecoration(
                        color: teamColor,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
              SizedBox(width: compact ? 6 : 8),
              if (_isEditing && nameController != null)
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 140 : 200),
                    child: TextField(
                      controller: nameController,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: compact ? 16 : null,
                      ),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 16 : null,
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            'Rating: ${effective.toStringAsFixed(1)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: compact ? 11 : null,
            ),
          ),
          const Divider(),
        ],
        ...sortedPlayers.map(
          (player) => MatchPlayerTile(
            player: player,
            trailing: const SizedBox.shrink(),
            dragData: _isEditing ? player.playerId : null,
            compact: compact,
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
            height: compact ? 48 : 60,
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

  Widget _buildCompactTeamHeader({
    required String fallbackLabel,
    required String? teamName,
    required String? colorHex,
    required TextEditingController? nameController,
    required double rating,
    required bool alignEnd,
    VoidCallback? onPickColor,
  }) {
    final theme = Theme.of(context);
    final teamColor = _parseColor(colorHex);
    final nameWidget = _isEditing && nameController != null
        ? SizedBox(
            width: 120,
            child: TextField(
              controller: nameController,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: fallbackLabel,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: const UnderlineInputBorder(),
              ),
            ),
          )
        : Text(
            _displayTeamName(teamName, fallbackLabel),
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    final colorBox = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: teamColor,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!alignEnd) ...[
              if (onPickColor != null)
                GestureDetector(
                  onTap: onPickColor,
                  child: Tooltip(message: 'Change color', child: colorBox),
                )
              else
                colorBox,
              const SizedBox(width: 6),
            ],
            Flexible(child: nameWidget),
            if (alignEnd) ...[
              const SizedBox(width: 6),
              if (onPickColor != null)
                GestureDetector(
                  onTap: onPickColor,
                  child: Tooltip(message: 'Change color', child: colorBox),
                )
              else
                colorBox,
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rating: ${rating.toStringAsFixed(1)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<PlayerDto> _availableSquadPlayers() {
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

  final List<PlayerDto> players;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < AppConfig.compactWidth;
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
                          compact: isCompact,
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
