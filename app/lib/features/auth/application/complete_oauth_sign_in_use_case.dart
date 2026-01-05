import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';
import 'package:app/features/users/domain/repositories/user_repository.dart';
import 'package:app/features/users/infrastructure/repositories/supabase_user_repository.dart';
import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class CompleteOAuthSignInUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;
  final UserRepository _userRepository;

  CompleteOAuthSignInUseCase(
    this._loginRepository,
    this._tokenRepository,
    this._userRepository,
  );

  Future<AuthEntity> execute(Uri redirectUri) async {
    final entity = await _loginRepository.getSessionFromRedirect(redirectUri);
    await _tokenRepository.setTokensFromEntity(entity);
    await _userRepository.getCurrentUser();
    return entity;
  }
}

final completeOAuthSignInUseCaseProvider = Provider<CompleteOAuthSignInUseCase>(
  (ref) {
    final loginRepository = ref.read(supabaseLoginClientProvider);
    final tokenRepository = ref.read(tokenSecureStorageProvider);
    final userRepository = ref.read(userRepositoryProvider);
    return CompleteOAuthSignInUseCase(
      loginRepository,
      tokenRepository,
      userRepository,
    );
  },
);
