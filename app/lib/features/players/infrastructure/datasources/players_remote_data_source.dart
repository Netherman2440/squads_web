import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/supabase_error_extension.dart';
import 'package:app/core/global_dependencies.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_model.dart';

class PlayersRemoteDataSource {
  PlayersRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  final Logger _logger = Logger('PlayersRemoteDataSource');

  Future<List<PlayerModel>> getPlayers(String squadId) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('squad_id', squadId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map(
            (row) => PlayerModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch players for squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  Future<PlayerModel> getPlayer(String playerId) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('player_id', playerId)
          .maybeSingle();

      if (response == null) {
        throw const NotFoundFailure('Player not found');
      }

      return PlayerModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      _logger.severe('Failed to fetch player $playerId', e, stack);
      throw e.toFailure();
    }
  }

  Future<PlayerModel> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseScore,
  }) async {
    final playerId = const Uuid().v4();
    final timestamp = DateTime.now().toIso8601String();

    try {
      final response = await _supabase
          .from('players')
          .insert({
            'player_id': playerId,
            'squad_id': squadId,
            'name': name,
            'position': position,
            'base_score': baseScore,
            'score': baseScore.toDouble(),
            'created_at': timestamp,
            'updated_at': timestamp,
            'is_deleted': false,
          })
          .select()
          .single();

      return PlayerModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      _logger.severe('Failed to add player $name to squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  Future<void> deletePlayer(String playerId) async {
    try {
      await _supabase
          .from('players')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('player_id', playerId);
    } catch (e, stack) {
      _logger.severe('Failed to delete player $playerId', e, stack);
      throw e.toFailure();
    }
  }

  Future<PlayerModel> updatePlayer({
    required String playerId,
    String? name,
    int? baseScore,
    double? score,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (baseScore != null) updates['base_score'] = baseScore;
      if (score != null) updates['score'] = score;

      final response = await _supabase
          .from('players')
          .update(updates)
          .eq('player_id', playerId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw const NotFoundFailure('Player not found');
      }

      return PlayerModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      _logger.severe('Failed to update player $playerId', e, stack);
      throw e.toFailure();
    }
  }
}

final playersRemoteDataSourceProvider =
    Provider<PlayersRemoteDataSource>((ref) {
  final supabase = ref.read(supabaseProvider);
  return PlayersRemoteDataSource(supabase);
});
