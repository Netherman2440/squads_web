import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';

class RegisterUseCase {
  final LoginRepository _loginRepository;

  RegisterUseCase(this._loginRepository);

  Future<AuthEntity> execute(
    String email,
    String password,
    String fullName,
  ) async {
    final entity = await _loginRepository.register(email, password, fullName);

    return entity;
  }
}

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  return RegisterUseCase(loginRepository);
});
