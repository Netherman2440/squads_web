import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/login_repository.dart';
import '../infrastructure/repositories/supabase_login_client.dart';

class RequestPasswordResetUseCase {
  final LoginRepository _loginRepository;

  RequestPasswordResetUseCase(this._loginRepository);

  Future<void> execute(String email, {String? redirectTo}) async {
    await _loginRepository.requestPasswordReset(email, redirectTo: redirectTo);
  }
}

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>((ref) {
      final repository = ref.read(supabaseLoginClientProvider);
      return RequestPasswordResetUseCase(repository);
    });
