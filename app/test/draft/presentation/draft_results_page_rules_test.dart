import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/draft/application/create_draft_use_case.dart';
import 'package:app/features/draft/application/get_player_pair_win_rates_use_case.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/domain/entities/head_to_head_win_rate.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/draft/domain/repositories/draft_stats_repository.dart';
import 'package:app/features/draft/presentation/pages/draft_results_page.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';
import 'package:app/features/players/domain/entities/player_stats.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';

void main() {
  testWidgets(
    'forwards draft rules from DraftResultsPage to draft repository',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final players = [
        _player('p1', 'Adam', 40),
        _player('p2', 'Bartek', 41),
        _player('p3', 'Cezary', 42),
        _player('p4', 'Dawid', 43),
      ];
      final repository = _CapturingDraftRepository();
      final draftRules = [
        const DraftRule(type: DraftRuleType.together, playerIds: ['p1', 'p2']),
        const DraftRule(type: DraftRuleType.against, playerIds: ['p3', 'p4']),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getSquadPlayersUseCaseProvider.overrideWithValue(
              GetSquadPlayersUseCase(_FakePlayerRepository(players)),
            ),
            combinatoryCreateDraftUseCaseProvider.overrideWithValue(
              CreateDraftUseCase(repository, enforceMaxPlayers: false),
            ),
            greedyCreateDraftUseCaseProvider.overrideWithValue(
              CreateDraftUseCase(repository, enforceMaxPlayers: false),
            ),
            getPlayerPairWinRatesUseCaseProvider.overrideWithValue(
              GetPlayerPairWinRatesUseCase(_FakeDraftStatsRepository()),
            ),
          ],
          child: MaterialApp(
            home: DraftResultsPage(
              squadId: 'squad-1',
              selectedPlayerIds: players
                  .map((player) => player.playerId)
                  .toList(),
              draftRules: draftRules,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final captured = repository.lastRules;
      expect(captured, isNotNull);
      expect(captured!.length, 2);
      expect(captured[0].type, DraftRuleType.together);
      expect(captured[0].playerIds, ['p1', 'p2']);
      expect(captured[1].type, DraftRuleType.against);
      expect(captured[1].playerIds, ['p3', 'p4']);
    },
  );
}

class _CapturingDraftRepository implements DraftRepository {
  List<DraftRule>? lastRules;

  @override
  Future<List<Draft>> createDraft({
    required List<Player> players,
    int teamCount = 2,
    List<DraftRule> rules = const [],
    int limit = 20,
    bool playWithSubstitute = true,
    int? seed,
  }) async {
    lastRules = rules
        .map(
          (rule) => DraftRule(type: rule.type, playerIds: [...rule.playerIds]),
        )
        .toList(growable: false);

    return [
      Draft.twoTeams(
        homePlayers: [players[0], players[2]],
        awayPlayers: [players[1], players[3]],
        homeTotalRanking: players[0].ranking + players[2].ranking,
        awayTotalRanking: players[1].ranking + players[3].ranking,
      ),
    ];
  }
}

class _FakeDraftStatsRepository implements DraftStatsRepository {
  @override
  Future<List<HeadToHeadWinRate>> getPlayerPairWinRates({
    required List<String> playerIds,
  }) async {
    return const [];
  }
}

class _FakePlayerRepository implements PlayerRepository {
  _FakePlayerRepository(this.players);

  final List<Player> players;

  @override
  Future<Player> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseRanking,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePlayer({required String playerId}) {
    throw UnimplementedError();
  }

  @override
  Future<Player> getPlayer({required String playerId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlayerHeadToHeadStat>> getPlayerHeadToHeadStats({
    required String playerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlayerStats> getPlayerStats({required String playerId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Player>> getSquadPlayers({required String squadId}) async {
    return players;
  }

  @override
  Future<Player> updatePlayer({
    required String playerId,
    String? name,
    String? position,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
  }) {
    throw UnimplementedError();
  }
}

Player _player(String id, String name, int ranking) {
  return Player(
    playerId: id,
    squadId: 'squad-1',
    name: name,
    baseRanking: ranking,
    ranking: ranking.toDouble(),
    createdAt: DateTime(2026, 1, 1),
  );
}
