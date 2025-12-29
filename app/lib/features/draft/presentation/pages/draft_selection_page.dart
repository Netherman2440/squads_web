import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/presentation/controllers/draft_selection_controller.dart';
import 'package:app/features/draft/presentation/widgets/draft_draggable_player_tile.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftSelectionPage extends ConsumerStatefulWidget {
  const DraftSelectionPage({
    super.key,
    required this.squadId,
    this.initialSelectedIds,
    this.matchId,
  });

  final String squadId;
  final List<String>? initialSelectedIds;
  final String? matchId;

  @override
  ConsumerState<DraftSelectionPage> createState() => _DraftSelectionPageState();
}

class _DraftSelectionPageState extends ConsumerState<DraftSelectionPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(draftSelectionControllerProvider.notifier)
          .loadPlayers(
            squadId: widget.squadId,
            initialSelectedIds: widget.initialSelectedIds,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftSelectionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft'),
        actions: [
          state.when(
            data: (data) {
              final canGenerate = data.selectedPlayerIds.length >= 2;

              return IconButton(
                tooltip: canGenerate
                    ? 'Generate draft'
                    : 'Select at least 2 players to generate draft',
                onPressed: canGenerate
                    ? () {
                        final ids = data.selectedPlayerIds.toList(
                          growable: false,
                        );
                        context.go(
                          '/squads/${widget.squadId}/matches/create',
                          extra: {
                            'selectedIds': ids,
                            'matchId': widget.matchId,
                          },
                        );
                      }
                    : null,
                icon: const Icon(Icons.auto_awesome),
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
                final isWide = constraints.maxWidth >= 900;

                final panels = [
                  Expanded(
                    child: _AvailablePlayersPanel(
                      players: available,
                      selectedCount: data.selectedPlayerIds.length,
                      searchQuery: data.searchQuery,
                      onSearchChanged: (value) => ref
                          .read(draftSelectionControllerProvider.notifier)
                          .setSearchQuery(value),
                      onToggle: (playerId) => ref
                          .read(draftSelectionControllerProvider.notifier)
                          .togglePlayer(playerId: playerId),
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),
                  Expanded(
                    child: _SelectedPlayersPanel(
                      players: selected,
                      selectedCount: data.selectedPlayerIds.length,
                      onToggle: (playerId) => ref
                          .read(draftSelectionControllerProvider.notifier)
                          .togglePlayer(playerId: playerId),
                      onClear: () => ref
                          .read(draftSelectionControllerProvider.notifier)
                          .clearSelection(),
                    ),
                  ),
                ];

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
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: panels,
                            )
                          : Column(children: panels),
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
}

class _AvailablePlayersPanel extends StatelessWidget {
  const _AvailablePlayersPanel({
    required this.players,
    required this.selectedCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onToggle,
  });

  final List<Player> players;
  final int selectedCount;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggle;

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
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.none,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Selected: $selectedCount / 16',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: players.isEmpty
                  ? const Center(child: Text('No available players.'))
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final p = players[index];
                        return DraftDraggablePlayerTile(
                          player: p,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => onToggle(p.playerId),
                          dragData: p.playerId,
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

class _SelectedPlayersPanel extends StatelessWidget {
  const _SelectedPlayersPanel({
    required this.players,
    required this.selectedCount,
    required this.onToggle,
    required this.onClear,
  });

  final List<Player> players;
  final int selectedCount;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

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
                  'Selected players ($selectedCount)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: selectedCount == 0 ? null : onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: players.isEmpty
                  ? const Center(child: Text('No players selected yet.'))
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final p = players[index];
                        return DraftDraggablePlayerTile(
                          player: p,
                          trailing: const Icon(Icons.remove_circle_outline),
                          onTap: () => onToggle(p.playerId),
                          dragData: p.playerId,
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
