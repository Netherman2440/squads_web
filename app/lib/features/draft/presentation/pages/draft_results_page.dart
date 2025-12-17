import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/presentation/controllers/draft_session_notifier.dart';
import 'package:app/features/draft/presentation/widgets/draft_draggable_player_tile.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftResultsPage extends ConsumerStatefulWidget {
  const DraftResultsPage({
    super.key,
    required this.squadId,
    required this.selectedPlayerIds,
  });

  final String squadId;
  final List<String> selectedPlayerIds;

  @override
  ConsumerState<DraftResultsPage> createState() => _DraftResultsPageState();
}

class _DraftResultsPageState extends ConsumerState<DraftResultsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(draftSessionNotifierProvider.notifier).load(
            squadId: widget.squadId,
            selectedPlayerIds: widget.selectedPlayerIds,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftSessionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: _CreateMatchStubButton(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => _ErrorBody(error: error),
        data: (data) {
          if (data.proposals.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No draft proposals. Go back and select players.'),
            );
          }

          final proposal = data.proposals[data.selectedIndex];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProposalNavigator(
                  index: data.selectedIndex,
                  total: data.proposals.length,
                  onPrev: data.selectedIndex == 0
                      ? null
                      : () => ref
                          .read(draftSessionNotifierProvider.notifier)
                          .selectProposal(data.selectedIndex - 1),
                  onNext: data.selectedIndex == data.proposals.length - 1
                      ? null
                      : () => ref
                          .read(draftSessionNotifierProvider.notifier)
                          .selectProposal(data.selectedIndex + 1),
                ),
                const SizedBox(height: 12),
                _TotalsRow(
                  homeTotal: _sum(data.home),
                  awayTotal: _sum(data.away),
                  proposalHomeTotal: proposal.homeTotalScore,
                  proposalAwayTotal: proposal.awayTotalScore,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;

                      final panels = [
                        Expanded(
                          child: _RosterPanel(
                            title: 'Home',
                            players: data.home,
                            onAcceptPlayerId: (playerId) => ref
                                .read(draftSessionNotifierProvider.notifier)
                                .movePlayer(
                                  playerId: playerId,
                                  toHome: true,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12, height: 12),
                        Expanded(
                          child: _RosterPanel(
                            title: 'Away',
                            players: data.away,
                            onAcceptPlayerId: (playerId) => ref
                                .read(draftSessionNotifierProvider.notifier)
                                .movePlayer(
                                  playerId: playerId,
                                  toHome: false,
                                ),
                          ),
                        ),
                      ];

                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: panels,
                            )
                          : Column(children: panels);
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
}

class _CreateMatchStubButton extends StatelessWidget {
  const _CreateMatchStubButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Create Match (not implemented yet)',
      onPressed: null,
      icon: const Icon(Icons.check_circle_outline),
    );
  }
}

class _ProposalNavigator extends StatelessWidget {
  const _ProposalNavigator({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Draft ${index + 1} of $total'),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.homeTotal,
    required this.awayTotal,
    required this.proposalHomeTotal,
    required this.proposalAwayTotal,
  });

  final double homeTotal;
  final double awayTotal;
  final double proposalHomeTotal;
  final double proposalAwayTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TotalChip(label: 'Home total', value: homeTotal),
        _TotalChip(label: 'Away total', value: awayTotal),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: ${value.toStringAsFixed(1)}'),
    );
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({
    required this.title,
    required this.players,
    required this.onAcceptPlayerId,
  });

  final String title;
  final List<Player> players;
  final ValueChanged<String> onAcceptPlayerId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final playerId = _extractPlayerId(details.data);
        if (playerId == null) {
          return false;
        }

        return !players.any((p) => p.playerId == playerId);
      },
      onAcceptWithDetails: (details) {
        final playerId = _extractPlayerId(details.data);
        if (playerId == null) {
          return;
        }

        onAcceptPlayerId(playerId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Card(
          shape: isHighlighted
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: players.isEmpty
                      ? const Center(
                          child: Text('No players.'),
                        )
                      : ListView.builder(
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            return DraftDraggablePlayerTile(
                              player: p,
                              trailing: const Icon(Icons.drag_indicator),
                              dragData: p.playerId,
                            );
                          },
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

double _sum(List<Player> players) {
  var total = 0.0;
  for (final p in players) {
    total += p.score;
  }
  return total;
}

String? _extractPlayerId(Object data) {
  if (data is String && data.isNotEmpty) {
    return data;
  }
  return null;
}
