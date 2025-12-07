import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:app/core/global_dependencies.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/user_repository.dart';

class SupabaseUserRepository implements UserRepository {
  final supabase.SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseUserRepository');

  SupabaseUserRepository(this._supabase);

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      final email = authUser.email ?? '';

      return domain.User(
        id: authUser.id,
        email: email,
      );
    } catch (e, stack) {
      _logger.severe('Failed to fetch current user', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateUser(domain.User user) async {
    await upsertUser(user);
  }

  @override
  Future<List<domain.User>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const [];
    }

    try {
      final response = await _supabase
          .from('users')
          .select('user_id, email')
          .inFilter('user_id', userIds);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return domain.User(
          id: map['user_id'] as String,
          email: (map['email'] as String?) ?? '',
        );
      }).toList();
    } catch (e, stack) {
      _logger.severe(
        'Failed to fetch users by ids $userIds',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> upsertUser(domain.User user) async {
    try {
      await _supabase.from('users').upsert(
        {
          'user_id': user.id,
          'email': user.email,
        },
        onConflict: 'user_id',
      );
    } catch (e, stack) {
      _logger.severe(
        'Failed to upsert public.users for id=${user.id}',
        e,
        stack,
      );
      rethrow;
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseUserRepository(supabase);
});


