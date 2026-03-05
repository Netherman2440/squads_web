import '../entities/ranking_history_entry.dart';

abstract class RankingRepository {
  /// Get all ranking history entries for a specific player, ordered by created_at DESC
  Future<List<RankingHistoryEntry>> getPlayerRankingHistory(String playerId);

  /// Get all ranking history entries for a specific match.
  Future<List<RankingHistoryEntry>> getMatchRankingHistory(String matchId);

  /// Get all ranking history entries for a specific tournament.
  Future<List<RankingHistoryEntry>> getTournamentRankingHistory(
    String tournamentId,
  );

  /// Get a specific ranking history entry by match_id
  Future<RankingHistoryEntry?> getRankingHistoryEntryByMatch({
    required String matchId,
    required String playerId,
  });

  /// Get a specific ranking history entry by tournament_id.
  Future<RankingHistoryEntry?> getRankingHistoryEntryByTournament({
    required String tournamentId,
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

  /// Updates the ranking change for a specific tournament entry.
  Future<double> updateTournamentRankingChange({
    required String playerId,
    required String tournamentId,
    required double newDelta,
  });

  /// Create initial ranking history entry when match is created (change = null)
  Future<RankingHistoryEntry> createMatchRankingEntry({
    required String playerId,
    required String matchId,
    required double currentRanking,
  });

  /// Create initial ranking history entry when tournament is created.
  Future<RankingHistoryEntry> createTournamentRankingEntry({
    required String playerId,
    required String tournamentId,
    required double currentRanking,
  });

  /// Delete ranking history entry for a match and revert the ranking change
  Future<void> deleteMatchRankingEntry({
    required String playerId,
    required String matchId,
  });

  /// Delete ranking history entry for a tournament and revert ranking change
  Future<void> deleteTournamentRankingEntry({
    required String playerId,
    required String tournamentId,
  });
}
