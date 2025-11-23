import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../application/apply_to_squad_use_case.dart';
import '../../application/create_squad_use_case.dart';
import '../../application/get_squads_use_case.dart';
import '../../domain/entities/squad.dart';

import '../../infrastructure/repositories/supabase_squad_repository.dart';
import 'squads_state.dart';

class SquadsNotifier extends Notifier<SquadsState> {
  @override
  SquadsState build() {
    return const SquadsState();
  }

  Future<void> loadSquads({String? searchQuery}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authState = ref.read(authStateProvider);
      final authEntity = authState.authEntity;

      final squads = await ref.read(getSquadsUseCaseProvider).execute(
            searchQuery: searchQuery,
            userId: authEntity?.userId,
            isGuest: authEntity == null || authEntity.isAnonymous,
          );

      state = state.copyWith(
        squads: squads,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load squads',
      );
    }
  }

  Future<void> createSquad(String name, SquadVisibility visibility) async {
    final authEntity = ref.read(authStateProvider).authEntity;
    if (authEntity == null || authEntity.isAnonymous) {
      state = state.copyWith(
        error: 'Login required to create squads',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await ref.read(createSquadUseCaseProvider).execute(
            name: name,
            visibility: visibility,
            ownerId: authEntity.userId,
            sportType: SportType.football,
          );

      if (!result.success) {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return;
      }

      await loadSquads();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create squad',
      );
    }
  }

  Future<void> applyToSquad(String squadId) async {
    final authEntity = ref.read(authStateProvider).authEntity;
    if (authEntity == null || authEntity.isAnonymous) {
      state = state.copyWith(
        error: 'Login required to apply to a squad',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(applyToSquadUseCaseProvider).execute(
            squadId,
            authEntity.userId,
          );

      await loadSquads();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to apply to squad',
      );
    }
  }

  Future<void> acceptInvite(String squadId) async {
    final authEntity = ref.read(authStateProvider).authEntity;
    if (authEntity == null || authEntity.isAnonymous) {
      state = state.copyWith(
        error: 'Login required to join squads',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(squadRepositoryProvider).addUserToSquad(
            squadId,
            authEntity.userId,
          );

      await loadSquads();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to accept squad invite',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
  
}

final squadsNotifierProvider = NotifierProvider<SquadsNotifier, SquadsState>(
  SquadsNotifier.new,
);
