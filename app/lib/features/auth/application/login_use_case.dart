import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';
import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class LoginResult {
  final AuthEntity? entity;
  final AuthFailure? failure;

  const LoginResult.success(AuthEntity this.entity) : failure = null;
  const LoginResult.failure(AuthFailure this.failure) : entity = null;

  bool get isSuccess => entity != null;
  bool get isFailure => failure != null;
}

class LoginUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  LoginUseCase(this._loginRepository, this._tokenRepository);

  Future<LoginResult> execute(String email, String password) async {
    try {
      final entity = await _loginRepository.login(email, password);
      if (entity == null) {
        return const LoginResult.failure(AuthFailure.invalidCredentials);
      }

      // Store tokens securely
      await _tokenRepository.setTokensFromEntity(entity);

      // Auto-refresh if refresh token exists
      if (entity.refreshToken.isNotEmpty) {
        final refreshed = await _loginRepository.refreshSession(entity.refreshToken);
        if (refreshed != null) {
          await _tokenRepository.setTokensFromEntity(refreshed);
        }
      }

      return LoginResult.success(entity);
    } catch (e) {
      return LoginResult.failure(AuthFailure.fromSupabaseError(e));
    }
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return LoginUseCase(loginRepository, tokenRepository);
});
