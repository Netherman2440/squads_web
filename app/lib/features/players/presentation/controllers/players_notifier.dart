import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/players/application/usecases/add_player_usecase.dart';
import 'package:app/features/players/application/usecases/delete_player_usecase.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';

class PlayersNotifier extends Notifier<AsyncValue<List<Player>>> {
  @override
  AsyncValue<List<Player>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadPlayers({required String squadId}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return ref.read(getSquadPlayersUseCaseProvider).execute(squadId: squadId);
    });
  }

  Future<void> refreshPlayers({required String squadId}) async {
    await loadPlayers(squadId: squadId);
  }

  Future<void> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseRanking,
  }) async {
    final authState = ref.read(authStateProvider);
    final authEntity = authState.value;

    if (authEntity == null || authEntity.isAnonymous) {
      state = AsyncValue.error(const UnauthorizedFailure(), StackTrace.current);
      return;
    }

    final previous = state;

    // We optimistically keep the list visible while adding a player.
    try {
      final player = await ref
          .read(addPlayerUseCaseProvider)
          .execute(
            squadId: squadId,
            name: name,
            position: position,
            baseRanking: baseRanking,
          );

      state = state.whenData((players) => [...players, player]);
    } catch (error, stack) {
      state = previous.when(
        data: (players) => AsyncValue.error(error, stack),
        error: (_, _) => AsyncValue.error(error, stack),
        loading: () => AsyncValue.error(error, stack),
      );
    }
  }

  Future<void> deletePlayer({
    required String squadId,
    required String playerId,
  }) async {
    final authState = ref.read(authStateProvider);
    final authEntity = authState.value;

    if (authEntity == null || authEntity.isAnonymous) {
      state = AsyncValue.error(const UnauthorizedFailure(), StackTrace.current);
      return;
    }

    final previous = state;

    try {
      await ref.read(deletePlayerUseCaseProvider).execute(playerId: playerId);

      state = state.whenData(
        (players) =>
            players.where((player) => player.playerId != playerId).toList(),
      );
    } catch (error, stack) {
      state = previous.when(
        data: (players) => AsyncValue.error(error, stack),
        error: (_, _) => AsyncValue.error(error, stack),
        loading: () => AsyncValue.error(error, stack),
      );
    }
  }
}

final playersNotifierProvider =
    NotifierProvider<PlayersNotifier, AsyncValue<List<Player>>>(
      PlayersNotifier.new,
    );
