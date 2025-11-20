import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_entity.dart';
import '../../application/login_use_case.dart';
import '../../application/register_use_case.dart';
import '../../application/guest_login_use_case.dart';
import '../../application/logout_use_case.dart';
import '../../application/refresh_session_use_case.dart';

class AuthState {
  final AuthEntity? authEntity;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.authEntity,
    this.isLoading = false,
    this.error,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  late final RefreshSessionUseCase _refreshSessionUseCase =
      ref.read(refreshSessionUseCaseProvider);
  late final LoginUseCase _loginUseCase = ref.read(loginUseCaseProvider);
  late final RegisterUseCase _registerUseCase =
      ref.read(registerUseCaseProvider);
  late final GuestLoginUseCase _guestLoginUseCase =
      ref.read(guestLoginUseCaseProvider);
  late final LogoutUseCase _logoutUseCase = ref.read(logoutUseCaseProvider);

  Future<void> init() async {
    state = const AuthState(
      authEntity: null,
      isLoading: true,
      error: null,
    );
    final result = await _refreshSessionUseCase.execute();
    if (result != null) {
      state = AuthState(authEntity: result, isLoading: false, error: null);
    } else {
      state = const AuthState(
        authEntity: null,
        isLoading: false,
        error: null,
      );
    }
  }

  @override
  AuthState build() {
    init();
    return const AuthState(authEntity: null, isLoading: false, error: null);
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = AuthState(
      authEntity: state.authEntity,
      isLoading: true,
      error: null,
    );
    final result = await _loginUseCase.execute(email, password);
    if (result.isFailure) {
      state = AuthState(
        authEntity: null,
        isLoading: false,
        error: result.failure!.message,
      );
      return false;
    }
    state = AuthState(authEntity: result.entity, isLoading: false, error: null);
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    state = AuthState(
      authEntity: state.authEntity,
      isLoading: true,
      error: null,
    );
    final result = await _registerUseCase.execute(email, password);
    if (result.isFailure) {
      state = AuthState(
        authEntity: null,
        isLoading: false,
        error: result.failure!.message,
      );
      return false;
    }

    // If user needs email confirmation, don't set auth entity yet
    if (result.needsEmailConfirmation) {
      state = const AuthState(
        authEntity: null,
        isLoading: false,
        error: 'Please check your email and click the confirmation link',
      );
      return false;
    }

    state = AuthState(authEntity: result.entity, isLoading: false, error: null);
    return true;
  }

  Future<bool> guestLogin() async {
    state = AuthState(
      authEntity: state.authEntity,
      isLoading: true,
      error: null,
    );
    final result = await _guestLoginUseCase.execute();
    if (result.isFailure) {
      state = AuthState(
        authEntity: null,
        isLoading: false,
        error: result.failure!.message,
      );
      return false;
    }
    state = AuthState(authEntity: result.entity, isLoading: false, error: null);
    return true;
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    state = const AuthState(
      authEntity: null,
      isLoading: false,
      error: null,
    );
  }

  void clearError() {
    if (state.error != null) {
      state = AuthState(
        authEntity: state.authEntity,
        isLoading: state.isLoading,
        error: null,
      );
    }
  }
}

final authStateProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
