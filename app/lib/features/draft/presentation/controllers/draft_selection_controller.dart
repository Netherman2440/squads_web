import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/presentation/state/draft_selection_state.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';

class DraftSelectionController
    extends Notifier<AsyncValue<DraftSelectionState>> {
  static const int _defaultTeamCount = 2;

  @override
  AsyncValue<DraftSelectionState> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadPlayers({
    required String squadId,
    List<String>? initialSelectedIds,
    List<DraftRule> initialRules = const [],
    int teamCount = _defaultTeamCount,
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

      final togetherGroups = <List<String>>[];
      final againstGroups = <List<String>>[];

      for (final rule in initialRules) {
        final ids = _sanitizeGroup(
          playerIds: rule.playerIds,
          allowedPlayerIds: initialSelected,
        );
        if (ids.length < 2) {
          continue;
        }
        switch (rule.type) {
          case DraftRuleType.together:
            togetherGroups.add(ids);
            break;
          case DraftRuleType.against:
            againstGroups.add(ids);
            break;
        }
      }

      final initialState = DraftSelectionState(
        players: players,
        selectedPlayerIds: initialSelected,
        togetherGroups: togetherGroups,
        againstGroups: againstGroups,
        teamCount: teamCount,
        searchQuery: '',
        validationMessage: null,
      );
      return _withValidation(initialState);
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
      final together = _pruneGroupsForSelection(
        groups: current.togetherGroups,
        selectedPlayerIds: selected,
        minSize: 2,
      );
      final against = _pruneGroupsForSelection(
        groups: current.againstGroups,
        selectedPlayerIds: selected,
        minSize: 2,
        maxSize: current.teamCount,
      );
      _setData(
        current.copyWith(
          selectedPlayerIds: selected,
          togetherGroups: together,
          againstGroups: against,
        ),
      );
      return;
    }

    selected.add(playerId);
    _setData(current.copyWith(selectedPlayerIds: selected));
  }

  void setSearchQuery(String value) {
    final current = state.value;
    if (current == null) {
      return;
    }

    _setData(current.copyWith(searchQuery: value));
  }

  void clearSelection() {
    final current = state.value;
    if (current == null) {
      return;
    }

    _setData(
      current.copyWith(
        selectedPlayerIds: <String>{},
        togetherGroups: const [],
        againstGroups: const [],
      ),
    );
  }

  void upsertTogetherGroup({required List<String> playerIds, int? index}) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final sanitized = _sanitizeGroup(
      playerIds: playerIds,
      allowedPlayerIds: current.selectedPlayerIds,
    );
    if (sanitized.length < 2) {
      return;
    }

    final updated = [...current.togetherGroups];
    final targetIndex = index ?? -1;
    if (targetIndex >= 0 && targetIndex < updated.length) {
      updated[targetIndex] = sanitized;
    } else {
      updated.add(sanitized);
    }
    _setData(current.copyWith(togetherGroups: updated));
  }

  void removeTogetherGroup(int index) {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (index < 0 || index >= current.togetherGroups.length) {
      return;
    }

    final updated = [...current.togetherGroups]..removeAt(index);
    _setData(current.copyWith(togetherGroups: updated));
  }

  void upsertAgainstGroup({required List<String> playerIds, int? index}) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final sanitized = _sanitizeGroup(
      playerIds: playerIds,
      allowedPlayerIds: current.selectedPlayerIds,
    );
    if (sanitized.length < 2) {
      return;
    }

    final updated = [...current.againstGroups];
    final targetIndex = index ?? -1;
    if (targetIndex >= 0 && targetIndex < updated.length) {
      updated[targetIndex] = sanitized;
    } else {
      updated.add(sanitized);
    }
    _setData(current.copyWith(againstGroups: updated));
  }

  void removeAgainstGroup(int index) {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (index < 0 || index >= current.againstGroups.length) {
      return;
    }

    final updated = [...current.againstGroups]..removeAt(index);
    _setData(current.copyWith(againstGroups: updated));
  }

  String? validateSelection() {
    final current = state.value;
    if (current == null) {
      return null;
    }
    final message = _validationMessage(current);
    state = AsyncValue.data(current.copyWith(validationMessage: message));
    return message;
  }

  void _setData(DraftSelectionState stateValue) {
    state = AsyncValue.data(_withValidation(stateValue));
  }

  DraftSelectionState _withValidation(DraftSelectionState stateValue) {
    return stateValue.copyWith(
      validationMessage: _validationMessage(stateValue),
    );
  }

  String? _validationMessage(DraftSelectionState value) {
    final selected = value.selectedPlayerIds;

    final togetherPlayerToGroup = <String, int>{};
    for (
      var groupIndex = 0;
      groupIndex < value.togetherGroups.length;
      groupIndex++
    ) {
      final group = value.togetherGroups[groupIndex];
      if (group.length < 2) {
        return 'Relacja "Razem" musi zawierać co najmniej 2 graczy.';
      }
      for (final playerId in group) {
        if (!selected.contains(playerId)) {
          return 'Relacje mogą zawierać tylko wybranych graczy.';
        }
        final existingGroup = togetherPlayerToGroup[playerId];
        if (existingGroup != null && existingGroup != groupIndex) {
          return 'Ten sam gracz nie może być w więcej niż jednej relacji "Razem".';
        }
        togetherPlayerToGroup[playerId] = groupIndex;
      }
    }

    for (final group in value.againstGroups) {
      if (group.toSet().length != group.length) {
        return 'Relacja "Przeciwko sobie" nie może zawierać duplikatów graczy.';
      }
      if (group.length > value.teamCount) {
        return 'Relacja "Przeciwko sobie" nie może mieć więcej graczy niż liczba drużyn (${value.teamCount}).';
      }
      if (group.length < 2) {
        return 'Relacja "Przeciwko sobie" musi mieć co najmniej 2 graczy.';
      }
      final togetherGroupsInAgainst = <int>{};
      for (final playerId in group) {
        if (!selected.contains(playerId)) {
          return 'Relacje mogą zawierać tylko wybranych graczy.';
        }
        final togetherGroupIndex = togetherPlayerToGroup[playerId];
        if (togetherGroupIndex != null &&
            !togetherGroupsInAgainst.add(togetherGroupIndex)) {
          return 'Relacja "Przeciwko sobie" nie może zawierać graczy z tej samej relacji "Razem".';
        }
      }
    }

    return null;
  }
}

final draftSelectionControllerProvider =
    NotifierProvider<DraftSelectionController, AsyncValue<DraftSelectionState>>(
      DraftSelectionController.new,
    );

List<String> _sanitizeGroup({
  required List<String> playerIds,
  required Set<String> allowedPlayerIds,
}) {
  final unique = <String>{};
  final result = <String>[];

  for (final playerId in playerIds) {
    if (!allowedPlayerIds.contains(playerId)) {
      continue;
    }
    if (!unique.add(playerId)) {
      continue;
    }
    result.add(playerId);
  }

  return result;
}

List<List<String>> _pruneGroupsForSelection({
  required List<List<String>> groups,
  required Set<String> selectedPlayerIds,
  required int minSize,
  int? maxSize,
}) {
  final next = <List<String>>[];
  for (final group in groups) {
    final filtered = _sanitizeGroup(
      playerIds: group,
      allowedPlayerIds: selectedPlayerIds,
    );
    if (filtered.length < minSize) {
      continue;
    }
    if (maxSize != null && filtered.length > maxSize) {
      continue;
    }
    next.add(filtered);
  }
  return next;
}
