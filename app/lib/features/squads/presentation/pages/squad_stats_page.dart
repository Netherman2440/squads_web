import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/squads/domain/entities/squad_stats.dart';
import 'package:app/features/squads/presentation/state/squad_stats_provider.dart';
import 'package:app/features/squads/presentation/widgets/stat_tile.dart';

class SquadStatsPage extends ConsumerWidget {
  const SquadStatsPage({super.key, required this.squadId});

  final String squadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(squadStatsProvider(squadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: statsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StatsErrorView(
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(squadStatsProvider(squadId)),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(squadStatsProvider(squadId).future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: _buildTiles(stats),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTiles(SquadStats stats) {
    final avgScoreText =
        '${stats.avgHomeGoals.toStringAsFixed(2)} : '
        '${stats.avgAwayGoals.toStringAsFixed(2)}';

    return [
      StatTile(label: 'Top player', value: stats.topPlayer),
      StatTile(label: 'Rising star', value: stats.topRisingStar),
      const Divider(),
      StatTile(label: 'Matches', value: stats.matchesCount),
      StatTile(label: 'Total goals', value: stats.totalGoals),
      StatTile(label: 'Home goals', value: stats.totalHomeGoals),
      StatTile(label: 'Away goals', value: stats.totalAwayGoals),
      StatTile(label: 'Avg goals per match', value: stats.avgGoalsPerMatch),
      StatTile(label: 'Avg score (home : away)', value: avgScoreText),
      const Divider(),
      StatTile(label: 'Players', value: stats.playersCount),
      StatTile(label: 'Avg player score', value: stats.avgPlayerScore),
    ];
  }

  String _errorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return 'Failed to load squad stats.';
  }
}

class _StatsErrorView extends StatelessWidget {
  const _StatsErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
