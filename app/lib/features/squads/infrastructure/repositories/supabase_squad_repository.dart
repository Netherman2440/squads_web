import 'package:app/core/error/supabase_error_extension.dart';
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
      var query = _supabase
          .from('squads')
          .select(
            'squad_id, owner_id, name, visibility, sport_type, created_at, '
            'ranking_update, ranking_multiplier, use_experience_factor, '
            'user_squads(count)',
          );

      if (visibility != null) {
        query = query.eq('visibility', visibility.name);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      if (sportType != null && sportType.isNotEmpty) {
        query = query.eq('sport_type', sportType);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((row) => Squad.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch squads', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<List<Squad>> getSquadsByIds(List<String> squadIds) async {
    if (squadIds.isEmpty) {
      return const [];
    }

    try {
      final query = _supabase
          .from('squads')
          .select(
            'squad_id, owner_id, name, visibility, sport_type, created_at, '
            'ranking_update, ranking_multiplier, use_experience_factor, '
            'user_squads(count)',
          );

      query.inFilter('squad_id', squadIds);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((row) => Squad.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch squads by ids', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<Squad?> getSquad(String squadId) async {
    try {
      final response = await _supabase
          .from('squads')
          .select(
            'squad_id, owner_id, name, visibility, sport_type, created_at, '
            'ranking_update, ranking_multiplier, use_experience_factor, '
            'user_squads(count)',
          )
          .eq('squad_id', squadId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Squad.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      _logger.severe('Failed to fetch squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<void> createSquad(
    String name,
    SquadVisibility visibility,
    String ownerId,
    String sportType,
  ) async {
    final squadId = const Uuid().v4();

    try {
      await _supabase.from('squads').insert({
        'squad_id': squadId,
        'owner_id': ownerId,
        'name': name,
        'visibility': visibility.name,
        'sport_type': sportType,
      });

      // Add owner as a member with 'owner' role
      await _supabase.from('user_squads').upsert({
        'squad_id': squadId,
        'user_id': ownerId,
        'role': SquadRole.owner.name,
      }, onConflict: 'squad_id,user_id');
    } catch (e, stack) {
      _logger.severe('Failed to create squad', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<void> updateSquad(
    String squadId, {
    String? name,
    SquadVisibility? visibility,
    bool? rankingUpdate,
    int? rankingMultiplier,
    bool? useExperienceFactor,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (visibility != null) updates['visibility'] = visibility.name;
      if (rankingUpdate != null) updates['ranking_update'] = rankingUpdate;
      if (rankingMultiplier != null) {
        updates['ranking_multiplier'] = rankingMultiplier;
      }
      if (useExperienceFactor != null) {
        updates['use_experience_factor'] = useExperienceFactor;
      }

      if (updates.isEmpty) return;

      await _supabase.from('squads').update(updates).eq('squad_id', squadId);
    } catch (e, stack) {
      _logger.severe('Failed to update squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<void> applyToSquad(String squadId, String userId) async {
    try {
      await _supabase.rpc(
        'request_squad_access',
        params: {'target_squad_id': squadId},
      );
    } catch (e, stack) {
      _logger.severe('Failed to apply to squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<void> addUserToSquad(String squadId, String userId) async {
    try {
      await _supabase.from('user_squads').upsert({
        'squad_id': squadId,
        'user_id': userId,
        'role': SquadRole.member.name,
      }, onConflict: 'squad_id,user_id');
    } catch (e, stack) {
      _logger.severe('Failed to add user $userId to squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<List<SquadMember>> getSquadMembers(String squadId) async {
    try {
      final response = await _supabase
          .from('user_squads')
          .select('user_id, squad_id, role')
          .eq('squad_id', squadId);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        map['squad_id'] = squadId;
        return SquadMember.fromMap(map);
      }).toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch squad members', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<String> joinSquadByCode(String code) async {
    try {
      final response = await _supabase.rpc(
        'join_squad_by_invite',
        params: {'invite_code': code},
      );

      final squadId = response as String?;
      if (squadId == null) {
        throw Exception('Join squad by invite returned null');
      }

      return squadId;
    } catch (e, stack) {
      _logger.severe('Failed to join squad via invite code', e, stack);
      throw e.toFailure();
    }
  }
}

final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseSquadRepository(supabase);
});
