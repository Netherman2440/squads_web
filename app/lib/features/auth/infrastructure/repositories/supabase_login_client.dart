import 'package:app/core/global_dependencies.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/login_repository.dart';

class SupabaseLoginClient implements LoginRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseLoginClient');

  SupabaseLoginClient(this._supabase);

  @override
  Future<AuthEntity?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        _logger.warning('Login failed: No user or session returned');
        return null;
      }

      final entity = AuthEntity(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken!,
        userId: response.user!.id,
        isAnonymous: false,
        email: response.user!.email!,
      );

      _logger.info('Login successful for user: ${response.user!.id}');
      return entity;
    } catch (e) {
      _logger.severe('Login failed: $e');
      return null;
    }
  }

  @override
  Future<AuthEntity?> register(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final session = response.session;
      final user = response.user;

      if (user == null) {
        _logger.warning('Registration failed: No user returned');
        return null;
      }

      // When email confirmation is enabled, session is null but user exists
      final entity = AuthEntity(
        accessToken: session?.accessToken ?? '',
        refreshToken: session?.refreshToken ?? '',
        userId: user.id,
        isAnonymous: false,
        email: user.email ?? email,
      );

      _logger.info('Registration successful for user: ${response.user!.id}');
      return entity;
    } on AuthException catch (e) {
      if (e.statusCode == '409') {
        _logger.warning('Registration failed: User already exists');
      } else {
        _logger.severe('Registration failed: $e');
      }
      throw e; // Re-throw to let use case handle it
    } catch (e) {
      _logger.severe('Registration failed: $e');
      throw e; // Re-throw to let use case handle it
    }
  }

  @override
  Future<AuthEntity?> guestLogin() async {
    try {
      final response = await _supabase.auth.signInAnonymously();

      if (response.user == null || response.session == null) {
        _logger.warning('Guest login failed: No user or session returned');
        return null;
      }

      final entity = AuthEntity(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken!,
        userId: response.user!.id,
        isAnonymous: true,
        email: '',
      );

      _logger.info('Guest login successful for user: ${response.user!.id}');
      return entity;
    } catch (e) {
      _logger.severe('Guest login failed: $e');
      return null;
    }
  }

  @override
  Future<AuthEntity?> refreshSession(String? refreshToken) async {
    if (refreshToken == null) {
      _logger.warning('Cannot refresh session: No refresh token provided');
      return null;
    }

    try {
      final response = await _supabase.auth.refreshSession(refreshToken);
      if (response.session == null) {
        _logger.warning('Session refresh failed: No session returned');
        return null;
      }
      return AuthEntity(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken!,
        userId: response.user!.id,
        isAnonymous: false,
        email: response.user!.email!,
      );
    } catch (e) {
      _logger.severe('Session refresh failed: $e');
      return null;
    }
  }
}

final supabaseLoginClientProvider = Provider<SupabaseLoginClient>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseLoginClient(supabase);
});
