import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/application/create_draft_use_case.dart';
import 'package:app/features/draft/presentation/state/draft_session_state.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';

enum DraftAlgorithm { combinatory, greedy }

class DraftAlgorithmNotifier extends Notifier<DraftAlgorithm> {
  @override
  DraftAlgorithm build() {
    return DraftAlgorithm.greedy;
  }

  void setAlgorithm(DraftAlgorithm algorithm) {
    Logger(
      'DraftAlgorithmNotifier',
    ).info('Can\'t change algorithm to $algorithm');
    state = DraftAlgorithm.greedy;
  }
}

final draftAlgorithmProvider =
    NotifierProvider<DraftAlgorithmNotifier, DraftAlgorithm>(
      DraftAlgorithmNotifier.new,
    );

class DraftSessionNotifier extends Notifier<AsyncValue<DraftSessionState>> {
  @override
  AsyncValue<DraftSessionState> build() {
    return const AsyncValue.loading();
  }

  Future<void> load({
    required String squadId,
    required List<String> selectedPlayerIds,
    required DraftAlgorithm algorithm,
    bool playWithSubstitute = true,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (selectedPlayerIds.length < 2) {
        throw const ValidationFailure('Draft requires at least 2 players.');
      }

      final allPlayers = await ref
          .read(getSquadPlayersUseCaseProvider)
          .execute(squadId: squadId);

      final selected = _filterByIds(
        players: allPlayers,
        ids: selectedPlayerIds,
      );

      final useCase = switch (algorithm) {
        DraftAlgorithm.combinatory => ref.read(
          combinatoryCreateDraftUseCaseProvider,
        ),
        DraftAlgorithm.greedy => ref.read(greedyCreateDraftUseCaseProvider),
      };

      final proposals = await useCase.execute(
        players: selected,
        playWithSubstitute: playWithSubstitute,
      );

      if (proposals.isEmpty) {
        return const DraftSessionState(
          proposals: [],
          selectedIndex: 0,
          home: [],
          away: [],
        );
      }

      final first = proposals.first;

      return DraftSessionState(
        proposals: proposals,
        selectedIndex: 0,
        home: first.homePlayers,
        away: first.awayPlayers,
      );
    });
  }

  void selectProposal(int index) {
    final current = state.value;
    if (current == null) {
      return;
    }

    if (index < 0 || index >= current.proposals.length) {
      return;
    }

    final proposal = current.proposals[index];

    state = AsyncValue.data(
      current.copyWith(
        selectedIndex: index,
        home: proposal.homePlayers,
        away: proposal.awayPlayers,
      ),
    );
  }

  void movePlayer({required String playerId, required bool toHome}) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final home = [...current.home];
    final away = [...current.away];

    Player? player;

    for (final p in home) {
      if (p.playerId == playerId) {
        player = p;
        break;
      }
    }
    if (player == null) {
      for (final p in away) {
        if (p.playerId == playerId) {
          player = p;
          break;
        }
      }
    }

    if (player == null) {
      return;
    }

    home.removeWhere((p) => p.playerId == playerId);
    away.removeWhere((p) => p.playerId == playerId);

    if (toHome) {
      home.add(player);
    } else {
      away.add(player);
    }

    state = AsyncValue.data(current.copyWith(home: home, away: away));
  }
}

final draftSessionNotifierProvider =
    NotifierProvider<DraftSessionNotifier, AsyncValue<DraftSessionState>>(
      DraftSessionNotifier.new,
    );

List<Player> _filterByIds({
  required List<Player> players,
  required List<String> ids,
}) {
  final byId = {for (final p in players) p.playerId: p};

  return ids.map(byId.remove).whereType<Player>().toList(growable: false);
}
