import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';

import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class RegisterUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  RegisterUseCase(this._loginRepository, this._tokenRepository);

  Future<AuthEntity> execute(String email, String password) async {
    final entity = await _loginRepository.register(email, password);

    // For registration with email confirmation, we might not get tokens immediately.
    // If accessToken is present, we treat it as logged in.
    if (entity.accessToken.isNotEmpty) {
      await _tokenRepository.setTokensFromEntity(entity);

      if (entity.refreshToken.isNotEmpty) {
        try {
          final refreshed = await _loginRepository.refreshSession(entity.refreshToken);
          await _tokenRepository.setTokensFromEntity(refreshed);
          return refreshed;
        } catch (_) {
          // Ignore refresh error
        }
      }
    }
    // If accessToken is empty, it means email confirmation is required.
    // We still return the entity, and UI handles the state.

    return entity;
  }
}

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return RegisterUseCase(loginRepository, tokenRepository);
});
