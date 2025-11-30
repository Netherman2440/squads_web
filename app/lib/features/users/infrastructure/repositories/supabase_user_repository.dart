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
    _logger.info(
      'updateUser is a no-op for now. '
      'Received user id=${user.id}, email=${user.email}',
    );
  }

}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseUserRepository(supabase);
});


