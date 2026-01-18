class PlayerHeadToHeadStat {
  final String otherPlayerId;
  final String otherName;
  final int togetherMatches;
  final int togetherWins;
  final int togetherDraws;
  final int togetherLosses;
  final int togetherGoalsFor;
  final int togetherGoalsAgainst;
  final int vsMatches;
  final int vsWins;
  final int vsDraws;
  final int vsLosses;
  final int vsGoalsFor;
  final int vsGoalsAgainst;

  const PlayerHeadToHeadStat({
    required this.otherPlayerId,
    required this.otherName,
    required this.togetherMatches,
    required this.togetherWins,
    required this.togetherDraws,
    required this.togetherLosses,
    required this.togetherGoalsFor,
    required this.togetherGoalsAgainst,
    required this.vsMatches,
    required this.vsWins,
    required this.vsDraws,
    required this.vsLosses,
    required this.vsGoalsFor,
    required this.vsGoalsAgainst,
  });

  factory PlayerHeadToHeadStat.fromMap(Map<String, dynamic> map) {
    int readInt(String key) {
      final value = map[key];
      if (value is num) return value.toInt();
      return 0;
    }

    return PlayerHeadToHeadStat(
      otherPlayerId: map['other_player_id'] as String,
      otherName: map['other_name'] as String? ?? '',
      togetherMatches: readInt('together_matches'),
      togetherWins: readInt('together_wins'),
      togetherDraws: readInt('together_draws'),
      togetherLosses: readInt('together_losses'),
      togetherGoalsFor: readInt('together_goals_for'),
      togetherGoalsAgainst: readInt('together_goals_against'),
      vsMatches: readInt('vs_matches'),
      vsWins: readInt('vs_wins'),
      vsDraws: readInt('vs_draws'),
      vsLosses: readInt('vs_losses'),
      vsGoalsFor: readInt('vs_goals_for'),
      vsGoalsAgainst: readInt('vs_goals_against'),
    );
  }
}
