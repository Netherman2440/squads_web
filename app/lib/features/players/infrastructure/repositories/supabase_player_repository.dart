import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/global_dependencies.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/core/error/supabase_error_extension.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class SupabasePlayerRepository implements PlayerRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabasePlayerRepository');

  SupabasePlayerRepository(this._supabase);

  @override
  Future<List<Player>> getSquadPlayers({
    required String squadId,
  }) async {
    try {
      final response = await _supabase
          .from('players')
          .select(
            '''
            player_id,
            squad_id,
            name,
            position,
            base_score,
            score,
            created_at
            ''',
          )
          .eq('squad_id', squadId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map(
            (row) => Player.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (e, stack) {
      _logger.severe(
        'Failed to fetch players for squad $squadId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<Player> getPlayer({
    required String playerId,
  }) async {
    try {
      final response = await _supabase
          .from('players')
          .select(
            '''
            player_id,
            squad_id,
            name,
            position,
            base_score,
            score,
            created_at
            ''',
          )
          .eq('player_id', playerId)
          .maybeSingle();

      if (response == null) {
        throw const NotFoundFailure('Player not found.');
      }

      return Player.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e, stack) {
      _logger.severe(
        'Failed to fetch player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<Player> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseScore,
  }) async {
    try {
      final playerId = const Uuid().v4();

      final response = await _supabase
          .from('players')
          .insert(
            {
              'player_id': playerId,
              'squad_id': squadId,
              'name': name,
              'position': position,
              'base_score': baseScore,
              'score': baseScore,
            },
          )
          .select(
            '''
            player_id,
            squad_id,
            name,
            position,
            base_score,
            score,
            created_at
            ''',
          )
          .maybeSingle();

      if (response == null) {
        throw const ServerFailure(
          'Failed to insert player. No data returned.',
        );
      }

      return Player.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e, stack) {
      _logger.severe(
        'Failed to add player to squad $squadId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<void> deletePlayer({
    required String playerId,
  }) async {
    try {
      await _supabase
          .from('players')
          .delete()
          .eq('player_id', playerId);
    } catch (e, stack) {
      _logger.severe(
        'Failed to delete player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<Player> updatePlayer({
    required String playerId,
    String? name,
    double? score,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) {
        updates['name'] = name;
      }
      if (score != null) {
        updates['score'] = score;
      }

      if (updates.isEmpty) {
        return getPlayer(playerId: playerId);
      }

      final response = await _supabase
          .from('players')
          .update(updates)
          .eq('player_id', playerId)
          .select(
            '''
            player_id,
            squad_id,
            name,
            position,
            base_score,
            score,
            created_at
            ''',
          )
          .maybeSingle();

      if (response == null) {
        throw const NotFoundFailure('Player not found.');
      }

      return Player.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e, stack) {
      _logger.severe(
        'Failed to update player $playerId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabasePlayerRepository(supabase);
});


