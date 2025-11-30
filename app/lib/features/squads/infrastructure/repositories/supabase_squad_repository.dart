import 'package:app/features/squads/domain/entities/squad_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/global_dependencies.dart';

import '../../domain/entities/squad.dart';
import '../../domain/entities/user_squad_role.dart';
import '../../domain/repositories/squad_repository.dart';

class SupabaseSquadRepository implements SquadRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseSquadRepository');

  SupabaseSquadRepository(this._supabase);

  @override
  Future<List<Squad>> getSquads({
    SquadVisibility? visibility,
    String? searchQuery,
    String? sportType,
  }) async {
    try {
      final query = _supabase.from('squads').select(
            'squad_id, owner_id, name, visibility, sport_type, created_at, user_squads(count)',
          );

      if (visibility != null) {
        query.eq('visibility', visibility.name);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query.ilike('name', '%$searchQuery%');
      }

      if (sportType != null && sportType.isNotEmpty) {
        query.eq('sport_type', sportType);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response = await orderedQuery;
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map(
            (row) => Squad.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch squads', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<Squad>> getSquadsByIds(List<String> squadIds) async {
    if (squadIds.isEmpty) {
      return const [];
    }

    try {
      final query = _supabase.from('squads').select(
            'squad_id, owner_id, name, visibility, sport_type, created_at, user_squads(count)',
          );

      // Supabase Dart client uses `inFilter` instead of `in_`.
      query.inFilter('squad_id', squadIds);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map(
            (row) => Squad.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch squads by ids', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> createSquad(
    String name,
    SquadVisibility visibility,
    String ownerId,
    String sportType,
  ) async {
    final newSquadId = const Uuid().v4();

    try {
      await _supabase.from('squads').insert({
            'squad_id': newSquadId,
            'name': name,
            'visibility': visibility.name,
            'owner_id': ownerId,
            'sport_type': sportType,
          });

      await _supabase.from('user_squads').upsert(
            {
              'squad_id': newSquadId,
              'user_id': ownerId,
              'role': SquadRole.owner.name,
            },
            onConflict: 'squad_id,user_id',
          );
    } catch (e, stack) {
      _logger.severe('Failed to create squad', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> applyToSquad(String squadId, String userId) async {
    try {
      await _supabase.from('user_squads').upsert(
            {
              'squad_id': squadId,
              'user_id': userId,
              'role': SquadRole.pending.name,
            },
            onConflict: 'squad_id,user_id',
          );
    } catch (e, stack) {
      _logger.severe('Failed to apply to squad $squadId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> addUserToSquad(String squadId, String userId) async {
    try {
      await _supabase.from('user_squads').upsert(
            {
              'squad_id': squadId,
              'user_id': userId,
              'role': SquadRole.member.name,
            },
            onConflict: 'squad_id,user_id',
          );
    } catch (e, stack) {
      _logger.severe('Failed to add user $userId to squad $squadId', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<SquadMember>> getSquadMembers(String squadId) async {
    try {
      final response = await _supabase
          .from('user_squads')
          .select('user_id, role, users(email)')
          .eq('squad_id', squadId);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        map['squad_id'] = squadId;
        return SquadMember.fromMap(map);
      }).toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch squad members', e, stack);
      rethrow;
    }
  }
}

final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseSquadRepository(supabase);
});
