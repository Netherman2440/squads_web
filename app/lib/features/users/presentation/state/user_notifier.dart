import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/users/application/get_current_user_use_case.dart';

import 'user_state.dart';

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState();
  }

  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await ref.read(getCurrentUserUseCaseProvider).execute();

      state = state.copyWith(isLoading: false, profile: profile, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nie udało się wczytać profilu użytkownika',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final userNotifierProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
