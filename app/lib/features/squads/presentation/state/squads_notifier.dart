import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/accept_invite_use_case.dart';
import '../../application/apply_to_squad_use_case.dart';
import '../../application/create_squad_use_case.dart';
import '../../application/get_squads_use_case.dart';
import '../../domain/entities/squad.dart';

class SquadsNotifier extends Notifier<AsyncValue<List<Squad>>> {
  @override
  AsyncValue<List<Squad>> build() {
    // Load initial data
    // We can't call async directly in build(), so we return loading and fire off the load.
    // Or better, we keep it simple and let the UI trigger load if it's not an auto-dispose provider that fetches on mount.
    // But standard Riverpod pattern is to return the future.

    // Ideally we should use future to load data.
    // For now, returning loading state and expecting the UI to trigger loadSquads
    // or calling it immediately.
    // Let's try to fetch immediately.

    // Note: We cannot use ref.read/watch inside the body of build if it's async
    // to set state, but we can return a Future to make it an AsyncNotifier.
    // However, the class is defined as Notifier, not AsyncNotifier.
    // Given the existing code was manual loading, I'll switch to AsyncNotifier
    // for better async handling.

    return const AsyncValue.loading();
  }

  Future<void> loadSquads({String? searchQuery}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref
          .read(getSquadsUseCaseProvider)
          .execute(searchQuery: searchQuery);
    });
  }

  Future<void> createSquad(String name, SquadVisibility visibility) async {
    // Optimistic update or loading state
    // For actions like create, we might want to keep the previous list and show a loading overlay,
    // but modifying state directly to loading will clear the list in UI if not handled.
    // We'll just set loading for now, as per previous behavior.
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      await ref
          .read(createSquadUseCaseProvider)
          .execute(
            name: name,
            visibility: visibility,
            sportType: SportType.football,
          );

      // Reload squads after creation
      return ref.read(getSquadsUseCaseProvider).execute();
    });

    state = result;
  }

  Future<void> applyToSquad(String squadId) async {
    // We don't necessarily need to set global loading for this action if we want to keep the list visible
    // but for simplicity and matching previous behavior:
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      await ref.read(applyToSquadUseCaseProvider).execute(squadId);
      return ref.read(getSquadsUseCaseProvider).execute();
    });

    state = result;
  }

  Future<void> acceptInvite(String squadId) async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      await ref.read(acceptInviteUseCaseProvider).execute(squadId: squadId);
      return ref.read(getSquadsUseCaseProvider).execute();
    });

    state = result;
  }
}

final squadsNotifierProvider =
    NotifierProvider<SquadsNotifier, AsyncValue<List<Squad>>>(
      SquadsNotifier.new,
    );
