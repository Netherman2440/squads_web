import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';

import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class RefreshSessionUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  RefreshSessionUseCase(
    this._loginRepository,
    this._tokenRepository,
  );

  /// Loads the latest tokens from secure storage and, if a refresh token is
  /// present, asks Supabase to refresh the session.
  /// Returns null if no token found or refresh failed (session expired).
  Future<AuthEntity?> execute() async {
    try {
      final stored = await _tokenRepository.getTokens();
      final refreshToken = stored?.refreshToken;
      if (refreshToken == null) {
        return null;
      }

      final refreshed = await _loginRepository.refreshSession(refreshToken);
      await _tokenRepository.setTokensFromEntity(refreshed);
      return refreshed;
    } catch (e) {
      // If refresh fails (e.g. token expired, network error), we return null
      // effectively logging the user out or indicating no active session.
      // We might want to log this error.
      return null;
    }
  }
}

final refreshSessionUseCaseProvider =
    Provider<RefreshSessionUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return RefreshSessionUseCase(loginRepository, tokenRepository);
});
