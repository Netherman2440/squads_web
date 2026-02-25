import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_config.dart';
import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/presentation/controllers/draft_selection_controller.dart';
import 'package:app/features/draft/presentation/state/draft_selection_state.dart';
import 'package:app/features/draft/presentation/widgets/draft_draggable_player_tile.dart';
import 'package:app/features/draft/presentation/widgets/draft_relation_widgets.dart';
import 'package:app/features/matches/presentation/controllers/create_match_controller.dart';
import 'package:app/features/matches/presentation/controllers/squad_matches_notifier.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftSelectionPage extends ConsumerStatefulWidget {
  const DraftSelectionPage({
    super.key,
    required this.squadId,
    this.initialSelectedIds,
    this.initialDraftRules = const [],
    this.matchId,
  });

  final String squadId;
  final List<String>? initialSelectedIds;
  final List<DraftRule> initialDraftRules;
  final String? matchId;

  @override
  ConsumerState<DraftSelectionPage> createState() => _DraftSelectionPageState();
}

class _DraftSelectionPageState extends ConsumerState<DraftSelectionPage> {
  bool _playWithSubstitute = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(draftSelectionControllerProvider.notifier)
          .loadPlayers(
            squadId: widget.squadId,
            initialSelectedIds: widget.initialSelectedIds,
            initialRules: widget.initialDraftRules,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftSelectionControllerProvider);
    final createMatchState = ref.watch(createMatchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft - wybór graczy'),
        actions: [
          state.when(
            data: (data) {
              final selectedCount = data.selectedPlayerIds.length;
              final hasMinimumPlayers = selectedCount >= 2;
              final isCreatingMatch = createMatchState.isLoading;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: hasMinimumPlayers && !isCreatingMatch
                          ? () => _generateWithoutRelations(data)
                          : null,
                      child: isCreatingMatch
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Wygeneruj draft'),
                    ),
                    TextButton(
                      onPressed: hasMinimumPlayers
                          ? () {
                              final ids = data.selectedPlayerIds.toList(
                                growable: false,
                              );
                              context.pushNamed(
                                AppRoute.draftRelations.name,
                                pathParameters: {'squadId': widget.squadId},
                                extra: {
                                  'selectedIds': ids,
                                  'matchId': widget.matchId,
                                  'playWithSubstitute': _playWithSubstitute,
                                  'draftRules': serializeDraftRules(
                                    data.draftRules,
                                  ),
                                },
                              );
                            }
                          : null,
                      child: const Text('Przejdź do relacji'),
                    ),
                    PopupMenuButton<_SelectionMenuAction>(
                      tooltip: 'Ustawienia draftu',
                      onSelected: (value) {
                        switch (value) {
                          case _SelectionMenuAction.toggleSubstitute:
                            setState(() {
                              _playWithSubstitute = !_playWithSubstitute;
                            });
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<_SelectionMenuAction>(
                          enabled: false,
                          child: SizedBox(
                            width: 280,
                            child: Text(
                              'Gra ze zmianami: przy nieparzystej liczbie '
                              'graczy większa drużyna gra ze zmianą.',
                            ),
                          ),
                        ),
                        CheckedPopupMenuItem<_SelectionMenuAction>(
                          value: _SelectionMenuAction.toggleSubstitute,
                          checked: _playWithSubstitute,
                          child: const Text('Gra ze zmianami'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(error: error),
        data: (data) {
          final available = _filterAvailable(
            players: data.players,
            selectedPlayerIds: data.selectedPlayerIds,
            query: data.searchQuery,
          );

          final selected = data.players
              .where((p) => data.selectedPlayerIds.contains(p.playerId))
              .toList(growable: false);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < AppConfig.compactWidth;

                final selectedPanel = Expanded(
                  flex: isCompact ? 5 : 2,
                  child: _SelectedPlayersPanel(
                    players: selected,
                    selectedCount: data.selectedPlayerIds.length,
                    compact: isCompact,
                    onToggle: (playerId) => ref
                        .read(draftSelectionControllerProvider.notifier)
                        .togglePlayer(playerId: playerId),
                    onClear: () => ref
                        .read(draftSelectionControllerProvider.notifier)
                        .clearSelection(),
                  ),
                );

                final availablePanel = Expanded(
                  flex: isCompact ? 4 : 3,
                  child: _AvailablePlayersPanel(
                    players: available,
                    selectedCount: data.selectedPlayerIds.length,
                    searchQuery: data.searchQuery,
                    compact: isCompact,
                    onSearchChanged: (value) => ref
                        .read(draftSelectionControllerProvider.notifier)
                        .setSearchQuery(value),
                    onToggle: (playerId) => ref
                        .read(draftSelectionControllerProvider.notifier)
                        .togglePlayer(playerId: playerId),
                  ),
                );

                return Column(
                  children: [
                    if (data.validationMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InlineErrorText(
                          message: data.validationMessage!,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          selectedPanel,
                          const SizedBox(height: 12),
                          availablePanel,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateWithoutRelations(DraftSelectionState data) async {
    final ids = data.selectedPlayerIds.toList(growable: false);

    var targetMatchId = widget.matchId;
    if (targetMatchId == null || targetMatchId.isEmpty) {
      final createdMatch = await ref
          .read(createMatchControllerProvider.notifier)
          .createMatch(
            squadId: widget.squadId,
            homePlayers: const <Player>[],
            awayPlayers: const <Player>[],
            rankingHistoryPlayerIds: ids,
          );
      targetMatchId = createdMatch?.matchId;

      if (targetMatchId == null || targetMatchId.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się utworzyć meczu.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ref.invalidate(squadMatchesProvider(widget.squadId));
    }

    if (!mounted) {
      return;
    }

    context.pushNamed(
      AppRoute.matchDraft.name,
      pathParameters: {'squadId': widget.squadId, 'matchId': targetMatchId},
      extra: {'selectedIds': ids, 'playWithSubstitute': _playWithSubstitute},
    );
  }
}

class _AvailablePlayersPanel extends StatefulWidget {
  const _AvailablePlayersPanel({
    required this.players,
    required this.selectedCount,
    required this.searchQuery,
    required this.compact,
    required this.onSearchChanged,
    required this.onToggle,
  });

  final List<Player> players;
  final int selectedCount;
  final String searchQuery;
  final bool compact;
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
              'Dostępni gracze',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Szukaj',
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.none,
              onChanged: widget.onSearchChanged,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.players.isEmpty
                  ? const Center(child: Text('Brak dostępnych graczy.'))
                  : Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final p = widget.players[index];
                          return DraftDraggablePlayerTile(
                            player: p,
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => widget.onToggle(p.playerId),
                            dragData: p.playerId,
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
    required this.onToggle,
    required this.onClear,
  });

  final List<Player> players;
  final int selectedCount;
  final bool compact;
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
                  'Wybrani gracze (${widget.selectedCount})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: widget.selectedCount == 0 ? null : widget.onClear,
                  child: const Text('Wyczyść'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.players.isEmpty
                  ? const Center(child: Text('Nie wybrano jeszcze graczy.'))
                  : Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final p = widget.players[index];
                          return DraftDraggablePlayerTile(
                            player: p,
                            trailing: const Icon(Icons.remove_circle_outline),
                            onTap: () => widget.onToggle(p.playerId),
                            dragData: p.playerId,
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

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final err = error;
    final message = err is Failure ? err.message : err.toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
        TextSpan(
          text: message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
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
  final q = query.trim().toLowerCase();

  return players
      .where((p) => !selectedPlayerIds.contains(p.playerId))
      .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
      .toList(growable: false);
}

enum _SelectionMenuAction { toggleSubstitute }
