import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/core/app_config.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/application/create_draft_use_case.dart';
import 'package:app/features/draft/application/get_match_draft_use_case.dart';
import 'package:app/features/draft/application/get_player_pair_win_rates_use_case.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/head_to_head_win_rate.dart';
import 'package:app/features/draft/domain/entities/stored_draft_payload.dart';
import 'package:app/features/draft/presentation/state/draft_session_state.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';

enum DraftAlgorithm { combinatory, greedy }

class DraftAlgorithmNotifier extends Notifier<DraftAlgorithm> {
  @override
  DraftAlgorithm build() {
    return DraftAlgorithm.combinatory;
  }

  void setAlgorithm(DraftAlgorithm algorithm) {
    Logger(
      'DraftAlgorithmNotifier',
    ).info('Draft algorithm changed to $algorithm');
    state = algorithm;
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
    String? matchId,
    bool playWithSubstitute = true,
  }) async {
    state = const AsyncValue.loading();
    await Future<void>.delayed(Duration.zero);

    state = await AsyncValue.guard(() async {
      final allPlayers = await ref
          .read(getSquadPlayersUseCaseProvider)
          .execute(squadId: squadId);

      if (selectedPlayerIds.isEmpty && matchId != null) {
        final storedDraft = await ref
            .read(getMatchDraftUseCaseProvider)
            .execute(matchId: matchId);

        if (storedDraft == null) {
          throw const NotFoundFailure('Draft not found for this match.');
        }

        if (storedDraft.status == 'error') {
          throw ValidationFailure(
            storedDraft.errorMessage ??
                'Draft for this match failed previously. Retry redraft.',
          );
        }

        final playersById = {
          for (final player in allPlayers) player.playerId: player,
        };
        final proposals = _restoreDraftsFromPayload(
          proposals: storedDraft.proposals,
          playersById: playersById,
        );
        final winRateMatrix = storedDraft.winRateMatrix;

        if (proposals.isEmpty) {
          return DraftSessionState(
            proposals: const [],
            selectedIndex: 0,
            home: const [],
            away: const [],
            winRateMatrix: winRateMatrix,
            homeWinProbability: 0.5,
          );
        }

        final first = proposals.first;
        final homeWinProbability = _calculateHomeWinProbability(
          home: first.homePlayers,
          away: first.awayPlayers,
          winRateMatrix: winRateMatrix,
        );

        return DraftSessionState(
          proposals: proposals,
          selectedIndex: 0,
          home: first.homePlayers,
          away: first.awayPlayers,
          winRateMatrix: winRateMatrix,
          homeWinProbability: homeWinProbability,
        );
      }

      if (selectedPlayerIds.length < 2) {
        throw const ValidationFailure('Draft requires at least 2 players.');
      }
      if (selectedPlayerIds.length > AppConfig.maxPlayersPerMatch) {
        throw ValidationFailure(
          'Draft supports up to ${AppConfig.maxPlayersPerMatch} players per match.',
        );
      }

      final selected = _filterByIds(
        players: allPlayers,
        ids: selectedPlayerIds,
      );
      if (selected.length > AppConfig.maxPlayersPerMatch) {
        throw ValidationFailure(
          'Draft supports up to ${AppConfig.maxPlayersPerMatch} players per match.',
        );
      }

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

      final winRates = await ref
          .read(getPlayerPairWinRatesUseCaseProvider)
          .execute(playerIds: selectedPlayerIds);

      final winRateMatrix = _buildWinRateMatrix(winRates);

      if (proposals.isEmpty) {
        return const DraftSessionState(
          proposals: [],
          selectedIndex: 0,
          home: [],
          away: [],
          winRateMatrix: {},
          homeWinProbability: 0.5,
        );
      }

      final first = proposals.first;
      final homeWinProbability = _calculateHomeWinProbability(
        home: first.homePlayers,
        away: first.awayPlayers,
        winRateMatrix: winRateMatrix,
      );

      return DraftSessionState(
        proposals: proposals,
        selectedIndex: 0,
        home: first.homePlayers,
        away: first.awayPlayers,
        winRateMatrix: winRateMatrix,
        homeWinProbability: homeWinProbability,
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
    final homeWinProbability = _calculateHomeWinProbability(
      home: proposal.homePlayers,
      away: proposal.awayPlayers,
      winRateMatrix: current.winRateMatrix,
    );

    state = AsyncValue.data(
      current.copyWith(
        selectedIndex: index,
        home: proposal.homePlayers,
        away: proposal.awayPlayers,
        homeWinProbability: homeWinProbability,
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

    final homeWinProbability = _calculateHomeWinProbability(
      home: home,
      away: away,
      winRateMatrix: current.winRateMatrix,
    );

    state = AsyncValue.data(
      current.copyWith(
        home: home,
        away: away,
        homeWinProbability: homeWinProbability,
      ),
    );
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

Map<String, Map<String, double>> _buildWinRateMatrix(
  List<HeadToHeadWinRate> winRates,
) {
  final matrix = <String, Map<String, double>>{};
  for (final rate in winRates) {
    final oppMap = matrix.putIfAbsent(rate.playerId, () => <String, double>{});
    oppMap[rate.oppPlayerId] = rate.winRate;
  }
  return matrix;
}

double _calculateHomeWinProbability({
  required List<Player> home,
  required List<Player> away,
  required Map<String, Map<String, double>> winRateMatrix,
}) {
  if (home.isEmpty || away.isEmpty) {
    return 0.5;
  }

  var total = 0.0;
  var count = 0;

  for (final homePlayer in home) {
    final oppRates = winRateMatrix[homePlayer.playerId];
    for (final awayPlayer in away) {
      final rate = oppRates?[awayPlayer.playerId] ?? 0.5;
      total += rate;
      count += 1;
    }
  }

  if (count == 0) {
    return 0.5;
  }

  final average = total / count;
  return average.clamp(0.0, 1.0);
}

List<Draft> _restoreDraftsFromPayload({
  required List<StoredDraftProposal> proposals,
  required Map<String, Player> playersById,
}) {
  final drafts = <Draft>[];

  for (final proposal in proposals) {
    final teams = <DraftTeam>[];
    final usedPlayerIds = <String>{};

    for (var teamIndex = 0; teamIndex < proposal.teams.length; teamIndex++) {
      final teamPlayerIds = proposal.teams[teamIndex];
      final players = <Player>[];
      var totalRanking = 0.0;

      for (final playerId in teamPlayerIds) {
        if (!usedPlayerIds.add(playerId)) {
          continue;
        }

        final player = playersById[playerId];
        if (player == null) {
          continue;
        }

        players.add(player);
        totalRanking += player.ranking;
      }

      teams.add(
        DraftTeam(
          index: teamIndex,
          players: players,
          totalRanking: totalRanking,
        ),
      );
    }

    if (teams.isNotEmpty) {
      drafts.add(Draft(teams: teams));
    }
  }

  return drafts;
}
