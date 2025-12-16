import 'package:flutter/material.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/presentation/widgets/score_box.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    required this.onTap,
  });

  final Match match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = match.createdAt;

    final now = DateTime.now();
    final isToday = now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == createdAt.year &&
        yesterday.month == createdAt.month &&
        yesterday.day == createdAt.day;

    final formattedDate = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';

    final timeLabel =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
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
      ),
    );
  }
}
