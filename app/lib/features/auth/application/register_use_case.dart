import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';
import 'package:app/features/users/domain/entities/user.dart' as domain_user;
import 'package:app/features/users/domain/repositories/user_repository.dart';
import 'package:app/features/users/infrastructure/repositories/supabase_user_repository.dart';

import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class RegisterUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;
  final UserRepository _userRepository;

  RegisterUseCase(
    this._loginRepository,
    this._tokenRepository,
    this._userRepository,
  );

  Future<AuthEntity> execute(String email, String password) async {
    final entity = await _loginRepository.register(email, password);

    // For registration with email confirmation, we might not get tokens immediately.
    // If accessToken is present, we treat it as logged in.
    AuthEntity result = entity;

    if (entity.accessToken.isNotEmpty) {
      await _tokenRepository.setTokensFromEntity(entity);

      if (entity.refreshToken.isNotEmpty) {
        try {
          final refreshed =
              await _loginRepository.refreshSession(entity.refreshToken);
          await _tokenRepository.setTokensFromEntity(refreshed);
          result = refreshed;
        } catch (_) {
          // Ignore refresh error, keep original entity.
        }
      }
    }

    // Sync minimal user profile into public.users for easier joins.
    await _userRepository.upsertUser(
      domain_user.User(
        id: result.userId,
        email: result.email,
      ),
    );

    // If accessToken is empty, it means email confirmation is required.
    // We still return the entity, and UI handles the state.
    return result;
  }
}

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  final userRepository = ref.read(userRepositoryProvider);
  return RegisterUseCase(
    loginRepository,
    tokenRepository,
    userRepository,
  );
});
