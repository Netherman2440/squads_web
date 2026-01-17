class PlayerStats {
  final double baseRanking;
  final double currentRanking;
  final int totalMatches;
  final int totalWins;
  final int totalDraws;
  final int totalLosses;
  final int winStreak;
  final int lossStreak;
  final int biggestWinStreak;
  final int biggestLossStreak;
  final int goalsScored;
  final int goalsConceded;
  final double avgGoalsPerMatch;
  final double avgScore;

  const PlayerStats({
    required this.baseRanking,
    required this.currentRanking,
    required this.totalMatches,
    required this.totalWins,
    required this.totalDraws,
    required this.totalLosses,
    required this.winStreak,
    required this.lossStreak,
    required this.biggestWinStreak,
    required this.biggestLossStreak,
    required this.goalsScored,
    required this.goalsConceded,
    required this.avgGoalsPerMatch,
    required this.avgScore,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    double readDouble(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is num) return value.toDouble();
      }
      return 0.0;
    }

    int readInt(String key) {
      final value = map[key];
      if (value is num) return value.toInt();
      return 0;
    }

    return PlayerStats(
      baseRanking: readDouble(['base_ranking', 'base_score']),
      currentRanking: readDouble(['current_ranking', 'ranking', 'score']),
      totalMatches: readInt('total_matches'),
      totalWins: readInt('total_wins'),
      totalDraws: readInt('total_draws'),
      totalLosses: readInt('total_losses'),
      winStreak: readInt('win_streak'),
      lossStreak: readInt('loss_streak'),
      biggestWinStreak: readInt('biggest_win_streak'),
      biggestLossStreak: readInt('biggest_loss_streak'),
      goalsScored: readInt('goals_scored'),
      goalsConceded: readInt('goals_conceded'),
      avgGoalsPerMatch: readDouble(['avg_goals_per_match']),
      avgScore: readDouble(['avg_score']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'base_ranking': baseRanking,
      'current_ranking': currentRanking,
      'total_matches': totalMatches,
      'total_wins': totalWins,
      'total_draws': totalDraws,
      'total_losses': totalLosses,
      'win_streak': winStreak,
      'loss_streak': lossStreak,
      'biggest_win_streak': biggestWinStreak,
      'biggest_loss_streak': biggestLossStreak,
      'goals_scored': goalsScored,
      'goals_conceded': goalsConceded,
      'avg_goals_per_match': avgGoalsPerMatch,
      'avg_score': avgScore,
    };
  }
}
