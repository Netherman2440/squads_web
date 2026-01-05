import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import '../domain/entities/auth_provider.dart';
import '../domain/repositories/login_repository.dart';

class OAuthSignInUseCase {
  final LoginRepository _loginRepository;

  OAuthSignInUseCase(this._loginRepository);

  Future<void> execute(AuthProvider provider, {String? redirectTo}) async {
    await _loginRepository.signInWithProvider(
      provider,
      redirectTo: redirectTo,
    );
  }
}

final oauthSignInUseCaseProvider = Provider<OAuthSignInUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  return OAuthSignInUseCase(loginRepository);
});
