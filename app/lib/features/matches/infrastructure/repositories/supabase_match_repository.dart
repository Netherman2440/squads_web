import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/supabase_error_extension.dart';
import 'package:app/core/global_dependencies.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';

class SupabaseMatchRepository implements MatchRepository {
  SupabaseMatchRepository(this._supabase);

  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseMatchRepository');

  @override
  Future<List<Match>> getSquadMatches({required String squadId}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select(
            '''
            match_id,
            squad_id,
            tournament_id,
            score_type,
            home_score,
            away_score,
            score_meta,
            created_at
            ''',
          )
          .eq('squad_id', squadId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      return data
          .map(
            (row) => Match.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error, stack) {
      _logger.severe(
        'Failed to fetch matches for squad $squadId',
        error,
        stack,
      );
      throw error.toFailure();
    }
  }

  @override
  Future<Match> getMatch({required String matchId}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select(
            '''
            match_id,
            squad_id,
            tournament_id,
            score_type,
            home_score,
            away_score,
            score_meta,
            created_at,
            teams (
              team_id,
              match_id,
              side,
              name,
              color,
              team_players (
                player_id,
                players (
                  player_id,
                  squad_id,
                  name,
                  position,
                  base_score,
                  score,
                  created_at
                )
              )
            )
            ''',
          )
          .eq('match_id', matchId)
          .maybeSingle();

      if (response == null) {
        throw const NotFoundFailure('Match not found.');
      }

      return Match.fromMap(Map<String, dynamic>.from(response as Map));
    } catch (error, stack) {
      _logger.severe(
        'Failed to fetch match $matchId',
        error,
        stack,
      );
      throw error.toFailure();
    }
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseMatchRepository(supabase);
});
