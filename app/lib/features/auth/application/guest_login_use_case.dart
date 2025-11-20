import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class GuestLoginResult {
  final AuthEntity? entity;
  final AuthFailure? failure;

  const GuestLoginResult.success(AuthEntity this.entity) : failure = null;
  const GuestLoginResult.failure(AuthFailure this.failure) : entity = null;

  bool get isSuccess => entity != null;
  bool get isFailure => failure != null;
}

class GuestLoginUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  GuestLoginUseCase(this._loginRepository, this._tokenRepository);

  Future<GuestLoginResult> execute() async {
    try {
      final entity = await _loginRepository.guestLogin();
      if (entity == null) {
        return const GuestLoginResult.failure(AuthFailure.guestLoginFailed);
      }

      // Store tokens securely
      await _tokenRepository.setTokensFromEntity(entity);

      // Auto-refresh if refresh token exists (usually not for guest)
      if (entity.refreshToken.isNotEmpty) {
        final refreshed = await _loginRepository.refreshSession(entity.refreshToken);
        if (refreshed != null) {
          await _tokenRepository.setTokensFromEntity(refreshed);
        }
      }

      return GuestLoginResult.success(entity);
    } catch (e) {
      return GuestLoginResult.failure(AuthFailure.fromSupabaseError(e));
    }
  }
}

//TODO add provider
final guestLoginUseCaseProvider = Provider<GuestLoginUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return GuestLoginUseCase(loginRepository, tokenRepository);
});
