import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_entity.dart';
import '../../application/login_use_case.dart';
import '../../application/register_use_case.dart';
import '../../application/guest_login_use_case.dart';
import '../../application/logout_use_case.dart';
import '../../application/oauth_sign_in_use_case.dart';
import '../../application/complete_oauth_sign_in_use_case.dart';
import '../../domain/entities/auth_provider.dart';
import '../../../../core/global_dependencies.dart';
import '../../infrastructure/repositories/token_secure_storage.dart';

class AuthNotifier extends Notifier<AsyncValue<AuthEntity?>> {
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
    final supabase = ref.read(supabaseProvider);
    final tokenRepository = ref.read(tokenSecureStorageProvider);

    AuthEntity? initial;
    final session = supabase.auth.currentSession;
    final user = session?.user;
    if (session != null && user != null) {
      initial = AuthEntity(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
        userId: user.id,
        isAnonymous: user.isAnonymous,
        email: user.email ?? '',
      );
    }

    final sub = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      final user = session?.user;

      try {
        if (event == AuthChangeEvent.signedOut) {
          await tokenRepository.clearTokens();
          state = const AsyncValue.data(null);
          return;
        }

        if (session == null || user == null) {
          state = const AsyncValue.data(null);
          return;
        }

        final entity = AuthEntity(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
          userId: user.id,
          isAnonymous: user.isAnonymous,
          email: user.email ?? '',
        );

        // Persist rotated refresh tokens as soon as Supabase emits them.
        await tokenRepository.setTokensFromEntity(entity);
        state = AsyncValue.data(entity);
      } catch (error, stackTrace) {
        // We keep the last known auth state if persistence fails.
        state = AsyncValue.error(error, stackTrace);
      }
    });

    ref.onDispose(sub.cancel);

    return AsyncValue.data(initial);
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
