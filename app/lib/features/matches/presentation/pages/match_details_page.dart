import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/app_router.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/entities/team.dart';
import 'package:app/features/matches/presentation/controllers/match_details_notifier.dart';

class MatchDetailsPage extends ConsumerWidget {
  final String squadId;
  final String matchId;

  const MatchDetailsPage({
    super.key,
    required this.squadId,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailsProvider(matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        actions: [
          // Edit buttons placeholder for later
        ],
      ),
      body: matchAsync.when(
        data: (match) => _MatchDetailsView(match: match, squadId: squadId),
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
}

class _MatchDetailsView extends StatelessWidget {
  final Match match;
  final String squadId;

  const _MatchDetailsView({required this.match, required this.squadId});

  @override
  Widget build(BuildContext context) {
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
          _buildScoreBoard(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTeamRoster(context, match.homeTeam!, 'Home'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamRoster(context, match.awayTeam!, 'Away'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context) {
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

  Widget _buildTeamRoster(BuildContext context, Team team, String label) {
    return Column(
      children: [
        Text(team.name ?? label, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        ...team.players.map(
          (player) => ListTile(
            title: Text(player.name),
            // Use ranking history snapshot logic later.
            // For now display current ranking or whatever is available in Player object.
            // Note: Match details should eventually fetch ranking snapshot.
            // The Player object from getMatch might need to be enriched or we rely on ranking_history.
            // For MVP, just name is fine.
            trailing: Text(player.ranking.toStringAsFixed(1)),
            onTap: () {
              context.pushNamed(
                AppRoute.playerDetails.name,
                pathParameters: {
                  'squadId': squadId,
                  'playerId': player.playerId,
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
