import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/login_repository.dart';
import '../infrastructure/repositories/supabase_login_client.dart';

class UpdatePasswordUseCase {
  final LoginRepository _loginRepository;

  UpdatePasswordUseCase(this._loginRepository);

  Future<void> execute(String newPassword) async {
    await _loginRepository.updatePassword(newPassword);
  }
}

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  final repository = ref.read(supabaseLoginClientProvider);
  return UpdatePasswordUseCase(repository);
});
