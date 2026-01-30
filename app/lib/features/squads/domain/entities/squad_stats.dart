import 'package:app/features/players/domain/entities/player.dart';

class SquadStats {
  final Player? topPlayer;
  final Player? worstPlayer;
  final Player? topRisingStar;
  final int matchesCount;
  final int totalGoals;
  final int totalHomeGoals;
  final int totalAwayGoals;
  final double avgGoalsPerMatch;
  final double avgHomeGoals;
  final double avgAwayGoals;
  final int playersCount;
  final double avgPlayerScore;

  const SquadStats({
    required this.topPlayer,
    required this.worstPlayer,
    required this.topRisingStar,
    required this.matchesCount,
    required this.totalGoals,
    required this.totalHomeGoals,
    required this.totalAwayGoals,
    required this.avgGoalsPerMatch,
    required this.avgHomeGoals,
    required this.avgAwayGoals,
    required this.playersCount,
    required this.avgPlayerScore,
  });

  factory SquadStats.fromMap(Map<String, dynamic> map) {
    Player? parsePlayer(Object? data) {
      if (data == null) return null;
      return Player.fromMap(Map<String, dynamic>.from(data as Map));
    }

    return SquadStats(
      topPlayer: parsePlayer(map['top_player']),
      worstPlayer: parsePlayer(map['worst_player']),
      topRisingStar: parsePlayer(map['top_rising_star']),
      matchesCount: (map['matches_count'] as num?)?.toInt() ?? 0,
      totalGoals: (map['total_goals'] as num?)?.toInt() ?? 0,
      totalHomeGoals: (map['total_home_goals'] as num?)?.toInt() ?? 0,
      totalAwayGoals: (map['total_away_goals'] as num?)?.toInt() ?? 0,
      avgGoalsPerMatch: (map['avg_goals_per_match'] as num?)?.toDouble() ?? 0,
      avgHomeGoals: (map['avg_home_goals'] as num?)?.toDouble() ?? 0,
      avgAwayGoals: (map['avg_away_goals'] as num?)?.toDouble() ?? 0,
      playersCount: (map['players_count'] as num?)?.toInt() ?? 0,
      avgPlayerScore: (map['avg_player_score'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'top_player': topPlayer?.toMap(),
      'worst_player': worstPlayer?.toMap(),
      'top_rising_star': topRisingStar?.toMap(),
      'matches_count': matchesCount,
      'total_goals': totalGoals,
      'total_home_goals': totalHomeGoals,
      'total_away_goals': totalAwayGoals,
      'avg_goals_per_match': avgGoalsPerMatch,
      'avg_home_goals': avgHomeGoals,
      'avg_away_goals': avgAwayGoals,
      'players_count': playersCount,
      'avg_player_score': avgPlayerScore,
    };
  }
}
