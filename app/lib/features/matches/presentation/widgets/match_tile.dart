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
    final homeTeamName = _displayTeamName(
      match.homeTeam?.name,
      'home',
    ).toUpperCase();
    final awayTeamName = _displayTeamName(
      match.awayTeam?.name,
      'away',
    ).toUpperCase();
    final homeTeamColor = _parseColor(match.homeTeam?.color);
    final awayTeamColor = _parseColor(match.awayTeam?.color);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _TeamColorBox(color: homeTeamColor),
                          ),
                          TextSpan(text: ' $homeTeamName', style: titleStyle),
                          TextSpan(text: '  -  ', style: titleStyle),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _TeamColorBox(color: awayTeamColor),
                          ),
                          TextSpan(text: ' $awayTeamName', style: titleStyle),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(match.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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

String _displayTeamName(String? name, String fallback) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? fallback : trimmed;
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

class _TeamColorBox extends StatelessWidget {
  final Color color;

  const _TeamColorBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
