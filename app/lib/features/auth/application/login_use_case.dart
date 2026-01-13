import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:app/features/auth/infrastructure/repositories/token_secure_storage.dart';
import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/repositories/token_repository.dart';

class LoginUseCase {
  final LoginRepository _loginRepository;
  final TokenRepository _tokenRepository;

  LoginUseCase(this._loginRepository, this._tokenRepository);

  Future<AuthEntity> execute(String email, String password) async {
    final entity = await _loginRepository.login(email, password);

    // Store tokens securely
    await _tokenRepository.setTokensFromEntity(entity);

    return entity;
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  final tokenRepository = ref.read(tokenSecureStorageProvider);
  return LoginUseCase(loginRepository, tokenRepository);
});
