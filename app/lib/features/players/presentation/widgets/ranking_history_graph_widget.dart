import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/ranking_history_entry.dart';

class RankingHistoryGraphWidget extends StatelessWidget {
  final List<RankingHistoryEntry> history;
  final double baseRanking;

  const RankingHistoryGraphWidget({
    super.key,
    required this.history,
    required this.baseRanking,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No ranking changes'),
        ),
      );
    }

    // Sort by created_at ASC for display on graph
    final sortedHistory = [...history]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final spots = <FlSpot>[];
    
    // Initial spot at base ranking
    // Wait, the plan says: "Each point on graph = entry.currentRanking"
    // and "First point starts at player.baseRanking"
    
    // We'll treat baseRanking as point 0 if it's the very first point.
    // Actually, each history entry represents a point in time.
    
    double currentRanking = baseRanking;
    spots.add(FlSpot(0, currentRanking));

    for (var i = 0; i < sortedHistory.length; i++) {
      final entry = sortedHistory[i];
      // The entry.ranking is the ranking BEFORE the change.
      // But we want to show the progression.
      // If we have history, it means there was a change.
      currentRanking = entry.currentRanking;
      spots.add(FlSpot((i + 1).toDouble(), currentRanking));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    
    final padding = (maxY - minY) * 0.1;
    final chartMinY = (minY - padding).floorToDouble();
    final chartMaxY = (maxY + padding).ceilToDouble();

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

