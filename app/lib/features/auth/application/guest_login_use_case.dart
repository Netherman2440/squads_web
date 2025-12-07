import 'package:app/features/auth/infrastructure/repositories/supabase_login_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/auth_entity.dart';
import '../domain/repositories/login_repository.dart';

class GuestLoginUseCase {
  final LoginRepository _loginRepository;

  GuestLoginUseCase(this._loginRepository);

  Future<AuthEntity> execute() async {
    final entity = await _loginRepository.guestLogin();
    // Note: Guest login usually doesn't persist tokens in the same way or might be session-only.
    // If persistence is needed, add TokenRepository here.
    return entity;
  }
}

final guestLoginUseCaseProvider = Provider<GuestLoginUseCase>((ref) {
  final loginRepository = ref.read(supabaseLoginClientProvider);
  return GuestLoginUseCase(loginRepository);
});
