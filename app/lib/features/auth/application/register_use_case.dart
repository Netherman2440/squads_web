
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';

import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class RegisterResult {
  final AuthEntity? entity;
  final AuthFailure? failure;

  const RegisterResult.success(AuthEntity this.entity) : failure = null;
  const RegisterResult.failure(AuthFailure this.failure) : entity = null;

  bool get isSuccess => entity != null;
  bool get isFailure => failure != null;

  /// True when registration succeeded but user needs email confirmation
  bool get needsEmailConfirmation => entity != null && entity!.accessToken.isEmpty;
}

class RegisterUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  RegisterUseCase(this._loginRepository, this._tokenRepository);

  Future<RegisterResult> execute(String email, String password) async {
    try {
      final entity = await _loginRepository.register(email, password);
      if (entity == null) {
        return const RegisterResult.failure(AuthFailure.registrationFailed);
      }

      // For registration with email confirmation, we don't get session immediately
      // We store the user data but wait for email confirmation
      if (entity.accessToken.isNotEmpty) {
        // User is immediately logged in (email confirmation disabled)
        await _tokenRepository.setTokensFromEntity(entity);

        if (entity.refreshToken.isNotEmpty) {
          final refreshed = await _loginRepository.refreshSession(entity.refreshToken);
          if (refreshed != null) {
            await _tokenRepository.setTokensFromEntity(refreshed);
          }
        }
      }
      // If accessToken is empty, user needs to confirm email

      return RegisterResult.success(entity);
    } catch (e) {
      return RegisterResult.failure(AuthFailure.fromSupabaseError(e));
    }
  }
}

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return RegisterUseCase(loginRepository, tokenRepository);
});
