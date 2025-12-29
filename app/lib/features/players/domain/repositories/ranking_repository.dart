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
  ///
  /// WARNING: This overwrites player.score based on entry.ranking + change.
  /// Use updateMatchRankingChange for safe historical updates.
  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
    String? matchId,
  });

  /// Updates the ranking change for a specific match.
  /// Handles historical updates by applying the difference (newDelta - oldDelta)
  /// to the current player score, preserving subsequent match changes.
  /// Returns the calculated difference (diff) that should be applied to the player's score.
  Future<double> updateMatchRankingChange({
    required String playerId,
    required String matchId,
    required double newDelta,
  });

  /// Create initial ranking history entry when match is created (change = null)
  Future<RankingHistoryEntry> createMatchRankingEntry({
    required String playerId,
    required String matchId,
    required double currentRanking,
  });

  /// Delete ranking history entry for a match and revert the ranking change
  Future<void> deleteMatchRankingEntry({
    required String playerId,
    required String matchId,
  });
}
