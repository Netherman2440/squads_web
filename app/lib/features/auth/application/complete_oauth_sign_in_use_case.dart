import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';
import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class CompleteOAuthSignInUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  CompleteOAuthSignInUseCase(this._loginRepository, this._tokenRepository);

  Future<AuthEntity> execute(Uri redirectUri) async {
    final entity = await _loginRepository.getSessionFromRedirect(redirectUri);
    await _tokenRepository.setTokensFromEntity(entity);
    return entity;
  }
}

final completeOAuthSignInUseCaseProvider = Provider<CompleteOAuthSignInUseCase>(
  (ref) {
    final loginRepository = ref.read(supabaseLoginClientProvider);
    final tokenRepository = ref.read(tokenSecureStorageProvider);
    return CompleteOAuthSignInUseCase(loginRepository, tokenRepository);
  },
);
