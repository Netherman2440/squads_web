import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/entities/team.dart';
import 'package:app/features/matches/presentation/controllers/match_details_notifier.dart';
import 'package:app/features/matches/presentation/widgets/score_box.dart';
import 'package:app/features/matches/presentation/widgets/team_roster_list.dart';
import 'package:app/features/players/domain/entities/player.dart';

class MatchDetailsPage extends ConsumerStatefulWidget {
  const MatchDetailsPage({
    super.key,
    required this.squadId,
    required this.matchId,
  });

  final String squadId;
  final String matchId;

  @override
  ConsumerState<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends ConsumerState<MatchDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(matchDetailsNotifierProvider.notifier).load(
            matchId: widget.matchId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchDetailsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match details'),
      ),
      body: matchState.when(
        data: (match) => _MatchDetailsBody(
          match: match,
          onPlayerTap: (player) => _openPlayer(context, player),
        ),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Failed to load match details\n\n',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  TextSpan(
                    text: error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context, Player player) {
    context.go('/squads/${widget.squadId}/players/${player.playerId}');
  }
}

class _MatchDetailsBody extends StatelessWidget {
  const _MatchDetailsBody({
    required this.match,
    required this.onPlayerTap,
  });

  final Match match;
  final void Function(Player player) onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeTeam = match.homeTeam;
    final awayTeam = match.awayTeam;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFullDate(match.createdAt),
                  style: theme.textTheme.titleMedium,
                ),
                if (match.scoreType != null)
                  Text(
                    match.scoreType!.label,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            Row(
              children: [
                ScoreBox(label: 'Home', score: match.homeScore),
                const SizedBox(width: 12),
                ScoreBox(label: 'Away', score: match.awayScore),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (homeTeam != null)
          _TeamSection(
            title: homeTeam.name ?? 'Home team',
            team: homeTeam,
            onPlayerTap: onPlayerTap,
          ),
        const SizedBox(height: 16),
        if (awayTeam != null)
          _TeamSection(
            title: awayTeam.name ?? 'Away team',
            team: awayTeam,
            onPlayerTap: onPlayerTap,
          ),
        if (homeTeam == null && awayTeam == null)
          const Text('Teams have not been assigned to this match yet.'),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.title,
    required this.team,
    required this.onPlayerTap,
  });

  final String title;
  final Team team;
  final void Function(Player player) onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TeamRosterList(
          team: team,
          onPlayerTap: onPlayerTap,
        ),
      ],
    );
  }
}
