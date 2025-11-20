
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
  Future<AuthEntity?> execute() async {
    final stored = await _tokenRepository.getTokens();
    final refreshToken = stored?.refreshToken;
    if (refreshToken == null) {
      return null;
    }

    final refreshed = await _loginRepository.refreshSession(refreshToken);
    if (refreshed == null) {
      return null;
    }

    await _tokenRepository.setTokensFromEntity(refreshed);
    return refreshed;
  }
}

final refreshSessionUseCaseProvider =
    Provider<RefreshSessionUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return RefreshSessionUseCase(loginRepository, tokenRepository);
});
