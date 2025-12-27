import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/player_details_controller.dart';
import '../widgets/ranking_history_graph_widget.dart';
import '../widgets/edit_player_name_dialog.dart';
import '../widgets/edit_player_ranking_dialog.dart';

class PlayerDetailsPage extends ConsumerWidget {
  final String squadId;
  final String playerId;

  const PlayerDetailsPage({
    super.key,
    required this.squadId,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(playerDetailsProvider(playerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Details'),
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: SelectableText.rich(
            TextSpan(
              text: 'Error: ${err.toString()}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (state) {
          final player = state.player;
          final history = state.rankingHistory;
          final difference = player.ranking - player.baseRanking;
          final isPositive = difference >= 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(
                        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Ranking: ${player.ranking.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(width: 12),
                              _RankingDifferenceIndicator(
                                difference: difference,
                                isPositive: isPositive,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => EditPlayerNameDialog(
                            playerId: playerId,
                            initialName: player.name,
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(playerDetailsProvider(playerId));
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Name'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => EditPlayerRankingDialog(
                            playerId: playerId,
                            currentRanking: player.ranking,
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(playerDetailsProvider(playerId));
                        }
                      },
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Edit Ranking'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Ranking History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RankingHistoryGraphWidget(
                      history: history,
                      baseRanking: player.baseRanking.toDouble(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _PlayerTabs(squadId: squadId, playerId: playerId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RankingDifferenceIndicator extends StatelessWidget {
  final double difference;
  final bool isPositive;

  const _RankingDifferenceIndicator({
    required this.difference,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (difference.abs() < 0.01) return const SizedBox.shrink();

    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          difference.abs().toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _PlayerTabs extends StatelessWidget {
  final String squadId;
  final String playerId;

  const _PlayerTabs({
    required this.squadId,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TabButton(
              label: 'Matches',
              icon: Icons.sports_soccer,
              onPressed: () => _showTodo(context),
            ),
            _TabButton(
              label: 'Tournaments',
              icon: Icons.emoji_events,
              onPressed: () => _showTodo(context),
            ),
            _TabButton(
              label: 'Stats',
              icon: Icons.analytics,
              onPressed: () => _showTodo(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showTodo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 32,
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

