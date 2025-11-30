import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/global_dependencies.dart';

import '../../domain/entities/membership.dart';
import '../../domain/entities/user_squad_role.dart';
import '../../domain/repositories/membership_repository.dart';

class SupabaseMembershipRepository implements MembershipRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseMembershipRepository');

  SupabaseMembershipRepository(this._supabase);

  @override
  Future<List<Membership>> getMembershipsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('user_squads')
          .select('user_id, squad_id, role, created_at')
          .eq('user_id', userId);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return Membership(
          userId: map['user_id'] as String,
          squadId: map['squad_id'] as String,
          role: SquadRoleParser.fromString(map['role'] as String?),
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch memberships for user $userId', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<Membership>> getMembershipsForSquad(String squadId) async {
    try {
      final response = await _supabase
          .from('user_squads')
          .select('user_id, squad_id, role, created_at')
          .eq('squad_id', squadId);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return Membership(
          userId: map['user_id'] as String,
          squadId: map['squad_id'] as String,
          role: SquadRoleParser.fromString(map['role'] as String?),
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch memberships for squad $squadId', e, stack);
      rethrow;
    }
  }
}

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseMembershipRepository(supabase);
});


