import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_entity.dart';
import '../../application/login_use_case.dart';
import '../../application/register_use_case.dart';
import '../../application/guest_login_use_case.dart';
import '../../application/logout_use_case.dart';
import '../../application/refresh_session_use_case.dart';
import '../../application/oauth_sign_in_use_case.dart';
import '../../application/complete_oauth_sign_in_use_case.dart';
import '../../domain/entities/auth_provider.dart';

class AuthNotifier extends Notifier<AsyncValue<AuthEntity?>> {
  late final RefreshSessionUseCase _refreshSessionUseCase = ref.read(
    refreshSessionUseCaseProvider,
  );
  late final LoginUseCase _loginUseCase = ref.read(loginUseCaseProvider);
  late final RegisterUseCase _registerUseCase = ref.read(
    registerUseCaseProvider,
  );
  late final GuestLoginUseCase _guestLoginUseCase = ref.read(
    guestLoginUseCaseProvider,
  );
  late final LogoutUseCase _logoutUseCase = ref.read(logoutUseCaseProvider);
  late final OAuthSignInUseCase _oauthSignInUseCase = ref.read(
    oauthSignInUseCaseProvider,
  );
  late final CompleteOAuthSignInUseCase _completeOAuthSignInUseCase = ref.read(
    completeOAuthSignInUseCaseProvider,
  );

  @override
  AsyncValue<AuthEntity?> build() {
    // Start with loading, then check session
    _init();
    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    // Use guard to handle errors automatically
    state = await AsyncValue.guard(() => _refreshSessionUseCase.execute());
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _loginUseCase.execute(email, password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final entity = await _registerUseCase.execute(email, password, fullName);

      // If email confirmation is required (no access token),
      // we might want to throw a specific message or handle it.
      // For now, returning the entity (even if partial) is fine.
      // The UI can check entity.accessToken.isEmpty if needed.
      return entity;
    });
  }

  Future<void> signInWithProvider({
    required AuthProvider provider,
    String? redirectTo,
  }) async {
    final previous = state.asData?.value;
    state = const AsyncValue.loading();
    try {
      await _oauthSignInUseCase.execute(provider, redirectTo: redirectTo);
      state = AsyncValue.data(previous);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeOAuthSignIn(Uri redirectUri) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _completeOAuthSignInUseCase.execute(redirectUri),
    );
  }

  Future<void> guestLogin() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _guestLoginUseCase.execute());
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _logoutUseCase.execute();
      return null;
    });
  }
}

final authStateProvider =
    NotifierProvider<AuthNotifier, AsyncValue<AuthEntity?>>(AuthNotifier.new);
