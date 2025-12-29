import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/global_dependencies.dart';
import 'package:app/core/error/supabase_error_extension.dart';

import '../../domain/entities/ranking_history_entry.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../../domain/exceptions/ranking_exceptions.dart';

class SupabaseRankingRepository implements RankingRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseRankingRepository');

  SupabaseRankingRepository(this._supabase);

  @override
  Future<List<RankingHistoryEntry>> getPlayerRankingHistory(
    String playerId,
  ) async {
    try {
      final response = await _supabase
          .from('ranking_history')
          .select()
          .eq('player_id', playerId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map(
            (row) => RankingHistoryEntry.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (e, stack) {
      _logger.severe(
        'Failed to fetch ranking history for player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<RankingHistoryEntry?> getRankingHistoryEntryByMatch({
    required String matchId,
    required String playerId,
  }) async {
    try {
      final response = await _supabase
          .from('ranking_history')
          .select()
          .eq('match_id', matchId)
          .eq('player_id', playerId)
          .maybeSingle();

      if (response == null) return null;

      return RankingHistoryEntry.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e, stack) {
      _logger.severe(
        'Failed to fetch ranking history for match $matchId and player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
    String? matchId,
  }) async {
    try {
      if (matchId != null) {
        // 1. Fetch existing ranking history entry
        final entry = await getRankingHistoryEntryByMatch(
          matchId: matchId,
          playerId: playerId,
        );
        if (entry == null) {
          throw RankingHistoryNotFoundException(
            'Ranking history entry not found for match $matchId',
          );
        }

        // 2. Check for newer entries with updates (conflict check)
        final newerEntriesResponse = await _supabase
            .from('ranking_history')
            .select('ranking_history_id')
            .eq('player_id', playerId)
            .gt('created_at', entry.createdAt.toIso8601String())
            .not('updated_at', 'is', null)
            .limit(1);

        if ((newerEntriesResponse as List).isNotEmpty) {
          throw RankingUpdateConflictException(
            'Cannot update: newer match result exists',
          );
        }

        // 3. Calculate change and update
        final change = newRanking - entry.ranking;

        // Update ranking history
        await _supabase
            .from('ranking_history')
            .update({
              'change': change,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('ranking_history_id', entry.rankingHistoryId);

        // Update player score
        await _supabase
            .from('players')
            .update({'score': newRanking})
            .eq('player_id', playerId);
      } else {
        // Manual adjustment
        // 1. Fetch current player ranking
        final playerResponse = await _supabase
            .from('players')
            .select('score')
            .eq('player_id', playerId)
            .single();

        final currentRanking = (playerResponse['score'] as num).toDouble();
        final change = newRanking - currentRanking;

        // 2. Create new history entry and update player
        await _supabase.from('ranking_history').insert({
          'player_id': playerId,
          'ranking': currentRanking,
          'change': change,
          'match_id': null,
        });

        await _supabase
            .from('players')
            .update({'score': newRanking})
            .eq('player_id', playerId);
      }
    } on RankingHistoryNotFoundException {
      rethrow;
    } on RankingUpdateConflictException {
      rethrow;
    } catch (e, stack) {
      _logger.severe(
        'Failed to update player ranking for player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<double> updateMatchRankingChange({
    required String playerId,
    required String matchId,
    required double newDelta,
  }) async {
    try {
      // 1. Fetch entry
      final entry = await getRankingHistoryEntryByMatch(
        matchId: matchId,
        playerId: playerId,
      );
      if (entry == null) {
        throw RankingHistoryNotFoundException('Entry not found');
      }

      // 2. Calculate diff
      final oldDelta = entry.change ?? 0.0;
      final diff = newDelta - oldDelta;

      if (diff == 0) return 0.0; // No change

      // 3. Update history
      await _supabase
          .from('ranking_history')
          .update({
            'change': newDelta,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('ranking_history_id', entry.rankingHistoryId);

      return diff;
    } catch (e, stack) {
      _logger.severe(
        'Failed to update match ranking change for player $playerId in match $matchId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<RankingHistoryEntry> createMatchRankingEntry({
    required String playerId,
    required String matchId,
    required double currentRanking,
  }) async {
    try {
      final response = await _supabase
          .from('ranking_history')
          .insert({
            'player_id': playerId,
            'match_id': matchId,
            'ranking': currentRanking,
            'change': null,
          })
          .select()
          .single();

      return RankingHistoryEntry.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e, stack) {
      _logger.severe(
        'Failed to create match ranking entry for player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<void> deleteMatchRankingEntry({
    required String playerId,
    required String matchId,
  }) async {
    try {
      // 1. Fetch entry
      final entry = await getRankingHistoryEntryByMatch(
        matchId: matchId,
        playerId: playerId,
      );
      if (entry == null) return; // Already gone

      // 2. Revert score
      final oldDelta = entry.change;
      if (oldDelta != null && oldDelta != 0) {
        final playerRes = await _supabase
            .from('players')
            .select('score')
            .eq('player_id', playerId)
            .single();
        final currentScore = (playerRes['score'] as num).toDouble();
        final newScore = currentScore - oldDelta;
        await _supabase
            .from('players')
            .update({'score': newScore})
            .eq('player_id', playerId);
      }

      // 3. Delete entry
      await _supabase
          .from('ranking_history')
          .delete()
          .eq('ranking_history_id', entry.rankingHistoryId);
    } catch (e, stack) {
      _logger.severe(
        'Failed to delete match ranking entry for player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }
}

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseRankingRepository(supabase);
});
