import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/app_config.dart';
import 'package:app/features/draft/presentation/state/draft_selection_state.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';

class DraftSelectionController
    extends Notifier<AsyncValue<DraftSelectionState>> {
  @override
  AsyncValue<DraftSelectionState> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadPlayers({
    required String squadId,
    List<String>? initialSelectedIds,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final players = await ref
          .read(getSquadPlayersUseCaseProvider)
          .execute(squadId: squadId);
      final selectablePlayerIds = players
          .map((player) => player.playerId)
          .toSet();
      final initialSelected = (initialSelectedIds?.toSet() ?? <String>{})
          .where(selectablePlayerIds.contains)
          .toSet();
      final validationMessage =
          initialSelected.length > AppConfig.maxPlayersPerMatch
          ? 'You can select up to ${AppConfig.maxPlayersPerMatch} players per match.'
          : null;

      return DraftSelectionState(
        players: players,
        selectedPlayerIds: initialSelected,
        searchQuery: '',
        validationMessage: validationMessage,
      );
    });
  }

  void togglePlayer({required String playerId}) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final selected = {...current.selectedPlayerIds};

    if (selected.contains(playerId)) {
      selected.remove(playerId);
      state = AsyncValue.data(
        current.copyWith(selectedPlayerIds: selected, validationMessage: null),
      );
      return;
    }

    selected.add(playerId);
    if (selected.length > AppConfig.maxPlayersPerMatch) {
      state = AsyncValue.data(
        current.copyWith(
          selectedPlayerIds: current.selectedPlayerIds,
          validationMessage:
              'You can select up to ${AppConfig.maxPlayersPerMatch} players per match.',
        ),
      );
      return;
    }

    state = AsyncValue.data(
      current.copyWith(selectedPlayerIds: selected, validationMessage: null),
    );
  }

  void setSearchQuery(String value) {
    final current = state.value;
    if (current == null) {
      return;
    }

    state = AsyncValue.data(current.copyWith(searchQuery: value));
  }

  void clearSelection() {
    final current = state.value;
    if (current == null) {
      return;
    }

    state = AsyncValue.data(
      current.copyWith(selectedPlayerIds: <String>{}, validationMessage: null),
    );
  }

  void validateSelection() {
    final current = state.value;
    if (current == null) {
      return;
    }

    if (current.selectedPlayerIds.length > AppConfig.maxPlayersPerMatch) {
      state = AsyncValue.data(
        current.copyWith(
          validationMessage:
              'You can select up to ${AppConfig.maxPlayersPerMatch} players per match.',
        ),
      );
      return;
    }

    state = AsyncValue.data(current.copyWith(validationMessage: null));
  }
}

final draftSelectionControllerProvider =
    NotifierProvider<DraftSelectionController, AsyncValue<DraftSelectionState>>(
      DraftSelectionController.new,
    );
