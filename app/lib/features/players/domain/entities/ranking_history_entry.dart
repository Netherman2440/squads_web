class RankingHistoryEntry {
  final String rankingHistoryId;
  final String playerId;
  final String? matchId;
  final String? tournamentId;
  final double ranking;
  final double? change;
  final Map<String, dynamic>? matchScore; // JSONB from matches feature
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed property: current ranking after applying change
  double get currentRanking => ranking + (change ?? 0);

  const RankingHistoryEntry({
    required this.rankingHistoryId,
    required this.playerId,
    this.matchId,
    this.tournamentId,
    required this.ranking,
    this.change,
    this.matchScore,
    required this.createdAt,
    this.updatedAt,
  });

  factory RankingHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RankingHistoryEntry(
      rankingHistoryId: map['ranking_history_id'] as String,
      playerId: map['player_id'] as String,
      matchId: map['match_id'] as String?,
      tournamentId: map['tournament_id'] as String?,
      ranking: (map['ranking'] as num).toDouble(),
      change: (map['change'] as num?)?.toDouble(),
      matchScore: map['match_score'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ranking_history_id': rankingHistoryId,
      'player_id': playerId,
      'match_id': matchId,
      'tournament_id': tournamentId,
      'ranking': ranking,
      'change': change,
      'match_score': matchScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
