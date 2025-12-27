import '../entities/ranking_history_entry.dart';

abstract class RankingRepository {
  /// Get all ranking history entries for a specific player, ordered by created_at DESC
  Future<List<RankingHistoryEntry>> getPlayerRankingHistory(String playerId);

  /// Get a specific ranking history entry by match_id
  Future<RankingHistoryEntry?> getRankingHistoryEntryByMatch({
    required String matchId,
    required String playerId,
  });

  /// Update player ranking (creates new ranking_history entry and updates player.ranking)
  /// If matchId is provided, validates and updates existing entry
  /// If matchId is null, creates manual adjustment entry
  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
    String? matchId,
  });

  /// Create initial ranking history entry when match is created (change = null)
  Future<RankingHistoryEntry> createMatchRankingEntry({
    required String playerId,
    required String matchId,
    required double currentRanking,
  });
}

