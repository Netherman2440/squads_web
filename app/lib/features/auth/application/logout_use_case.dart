
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';

import '../domain/repositories/token_repository.dart';
import '../../../core/global_dependencies.dart';

class LogoutUseCase {
  final TokenRepository _tokenRepository;
  final SupabaseClient _supabase;

  LogoutUseCase(this._tokenRepository, this._supabase);

  Future<void> execute() async {
    try {
      // Clear stored tokens
      await _tokenRepository.clearTokens();

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      // Log error but do not rethrow - logout should best-effort complete
      // In UI we can still consider user logged out.
    }
  }
}

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  final supabase = ref.read(supabaseProvider);
  return LogoutUseCase(tokenRepository, supabase);
});
