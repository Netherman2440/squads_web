import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_config.dart';
import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/presentation/widgets/draft_draggable_player_tile.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/application/usecases/create_tournament_usecase.dart';

class CreateTournamentPage extends ConsumerStatefulWidget {
  const CreateTournamentPage({super.key, required this.squadId});

  final String squadId;

  @override
  ConsumerState<CreateTournamentPage> createState() =>
      _CreateTournamentPageState();
}

class _CreateTournamentPageState extends ConsumerState<CreateTournamentPage> {
  static const List<int> _teamCountOptions = [2, 3, 4];

  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  List<Player> _players = const [];
  final Set<String> _selectedIds = <String>{};
  int _teamCount = 3;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPlayers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final players = await ref
          .read(getSquadPlayersUseCaseProvider)
          .execute(squadId: widget.squadId);

      if (!mounted) {
        return;
      }

      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error is Failure ? error.message : error.toString();
        _isLoading = false;
      });
    }
  }

  void _togglePlayer(String playerId) {
    setState(() {
      if (_selectedIds.contains(playerId)) {
        _selectedIds.remove(playerId);
      } else {
        _selectedIds.add(playerId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<String?> _createTournament() async {
    if (_selectedIds.length < _teamCount) {
      return null;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final tournament = await ref
          .read(createTournamentUseCaseProvider)
          .execute(
            squadId: widget.squadId,
            playerIds: _selectedIds.toList(growable: false),
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );

      return tournament.tournamentId;
    } catch (error) {
      if (!mounted) {
        return null;
      }

      setState(() {
        _error = error is Failure ? error.message : error.toString();
      });
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createAndContinue() async {
    final tournamentId = await _createTournament();
    if (!mounted || tournamentId == null) {
      return;
    }

    context.pushNamed(
      AppRoute.tournamentDraftRelations.name,
      pathParameters: {'squadId': widget.squadId, 'tournamentId': tournamentId},
      extra: {
        'selectedIds': _selectedIds.toList(growable: false),
        'teamCount': _teamCount,
        'draftRules': _encodeDraftRules(const []),
      },
    );
  }

  Future<void> _createAndGenerate() async {
    final tournamentId = await _createTournament();
    if (!mounted || tournamentId == null) {
      return;
    }

    context.pushNamed(
      AppRoute.tournamentDraft.name,
      pathParameters: {'squadId': widget.squadId, 'tournamentId': tournamentId},
      extra: {
        'selectedIds': _selectedIds.toList(growable: false),
        'teamCount': _teamCount,
        'draftRules': _encodeDraftRules(const []),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final squadAsync = ref.watch(squadDetailProvider(widget.squadId));
    final canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;
    final canEdit = canManage && !_isSubmitting;
    final isNarrow =
        MediaQuery.sizeOf(context).width < AppConfig.wideLayoutWidth;

    final selectedPlayers = _players
        .where((player) => _selectedIds.contains(player.playerId))
        .toList(growable: false);
    final availablePlayers = _filterAvailable(
      players: _players,
      selectedPlayerIds: _selectedIds,
      query: _searchController.text,
    );

    final teamCountBorderColor = _teamCount == 3
        ? Colors.green.shade600
        : Theme.of(context).colorScheme.outlineVariant;
    final teamCountBackgroundColor = _teamCount == 3
        ? Colors.green.withValues(alpha: 0.08)
        : Colors.transparent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: canEdit && _selectedIds.length >= _teamCount
                      ? _createAndGenerate
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isNarrow ? 'Draft' : 'Wygeneruj draft'),
                ),
                TextButton(
                  onPressed: canEdit && _selectedIds.length >= _teamCount
                      ? _createAndContinue
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(isNarrow ? 'Relacje' : 'Przejdź do relacji'),
                ),
                const SizedBox(width: 8),
                if (!isNarrow) const Text('Teams'),
                if (!isNarrow) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: teamCountBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: teamCountBorderColor,
                      width: _teamCount == 3 ? 2 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _teamCount,
                      style: Theme.of(context).textTheme.titleMedium,
                      iconSize: 24,
                      itemHeight: 52,
                      items: _teamCountOptions
                          .map(
                            (count) => DropdownMenuItem<int>(
                              value: count,
                              child: Text('$count'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: !canEdit
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _teamCount = value;
                              });
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Tournament name (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InlineErrorText(message: _error!),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact =
                            constraints.maxWidth < AppConfig.compactWidth;

                        final selectedPanel = Expanded(
                          flex: isCompact ? 5 : 2,
                          child: _SelectedPlayersPanel(
                            players: selectedPlayers,
                            selectedCount: _selectedIds.length,
                            compact: isCompact,
                            canManage: canEdit,
                            onToggle: _togglePlayer,
                            onClear: _clearSelection,
                          ),
                        );

                        final availablePanel = Expanded(
                          flex: isCompact ? 4 : 3,
                          child: _AvailablePlayersPanel(
                            players: availablePlayers,
                            compact: isCompact,
                            canManage: canEdit,
                            searchController: _searchController,
                            onSearchChanged: (_) => setState(() {}),
                            onToggle: _togglePlayer,
                          ),
                        );

                        return Column(
                          children: [
                            selectedPanel,
                            const SizedBox(height: 12),
                            availablePanel,
                          ],
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

class _AvailablePlayersPanel extends StatefulWidget {
  const _AvailablePlayersPanel({
    required this.players,
    required this.compact,
    required this.canManage,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggle,
  });

  final List<Player> players;
  final bool compact;
  final bool canManage;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggle;

  @override
  State<_AvailablePlayersPanel> createState() => _AvailablePlayersPanelState();
}

class _AvailablePlayersPanelState extends State<_AvailablePlayersPanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available players',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.searchController,
              decoration: const InputDecoration(
                labelText: 'Search players',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: widget.onSearchChanged,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.players.isEmpty
                  ? const Center(child: Text('No available players.'))
                  : Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final player = widget.players[index];
                          return DraftDraggablePlayerTile(
                            player: player,
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: widget.canManage
                                ? () => widget.onToggle(player.playerId)
                                : null,
                            compact: widget.compact,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPlayersPanel extends StatefulWidget {
  const _SelectedPlayersPanel({
    required this.players,
    required this.selectedCount,
    required this.compact,
    required this.canManage,
    required this.onToggle,
    required this.onClear,
  });

  final List<Player> players;
  final int selectedCount;
  final bool compact;
  final bool canManage;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  State<_SelectedPlayersPanel> createState() => _SelectedPlayersPanelState();
}

class _SelectedPlayersPanelState extends State<_SelectedPlayersPanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected players (${widget.selectedCount})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: !widget.canManage || widget.selectedCount == 0
                      ? null
                      : widget.onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.players.isEmpty
                  ? const Center(child: Text('No selected players yet.'))
                  : Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final player = widget.players[index];
                          return DraftDraggablePlayerTile(
                            player: player,
                            trailing: const Icon(Icons.remove_circle_outline),
                            onTap: widget.canManage
                                ? () => widget.onToggle(player.playerId)
                                : null,
                            compact: widget.compact,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        text: message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

List<Player> _filterAvailable({
  required List<Player> players,
  required Set<String> selectedPlayerIds,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return players
      .where((player) => !selectedPlayerIds.contains(player.playerId))
      .where(
        (player) =>
            normalizedQuery.isEmpty ||
            player.name.toLowerCase().contains(normalizedQuery),
      )
      .toList(growable: false);
}

List<Map<String, dynamic>> _encodeDraftRules(List<DraftRule> rules) {
  return [
    for (final rule in rules)
      {'type': rule.type.name, 'playerIds': rule.playerIds},
  ];
}
