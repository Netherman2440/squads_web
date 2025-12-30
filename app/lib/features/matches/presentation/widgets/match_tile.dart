import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/app_router.dart';

class MatchTile extends StatelessWidget {
  final Match match;
  final String squadId;

  const MatchTile({super.key, required this.match, required this.squadId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    // Determine result display
    // If no score, show "Pending" or similar?
    // MD says "wynik: dwa boxy jak w legacy (puste gdy brak wyniku)"

    final hasScore = match.homeScore != null && match.awayScore != null;
    final homeScore = hasScore ? match.homeScore.toString() : '-';
    final awayScore = hasScore ? match.awayScore.toString() : '-';

    return Card(
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoute.matchDetails.name,
            pathParameters: {'squadId': squadId, 'matchId': match.matchId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(match.createdAt.toLocal()),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (match.tournamentId != null)
                    Text(
                      'Tournament Match', // Ideally fetch tournament name
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              Row(
                children: [
                  _ScoreBox(score: homeScore),
                  const SizedBox(width: 8),
                  const Text(':'),
                  const SizedBox(width: 8),
                  _ScoreBox(score: awayScore),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String score;

  const _ScoreBox({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        score,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
