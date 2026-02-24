import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/draft/presentation/controllers/draft_selection_controller.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';
import 'package:app/features/players/domain/entities/player_stats.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';

void main() {
  test(
    'allows overlap between together and against when rules do not contradict',
    () async {
      final container = ProviderContainer(
        overrides: [
          getSquadPlayersUseCaseProvider.overrideWithValue(
            GetSquadPlayersUseCase(_FakePlayerRepository(_players())),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        draftSelectionControllerProvider.notifier,
      );
      await notifier.loadPlayers(
        squadId: 'squad-1',
        initialSelectedIds: const ['p1', 'p2', 'p3'],
      );

      notifier.upsertTogetherGroup(playerIds: const ['p1', 'p2']);
      notifier.upsertAgainstGroup(playerIds: const ['p1', 'p3']);

      final message = notifier.validateSelection();
      expect(message, isNull);
    },
  );

  test(
    'rejects against group with players from the same together group',
    () async {
      final container = ProviderContainer(
        overrides: [
          getSquadPlayersUseCaseProvider.overrideWithValue(
            GetSquadPlayersUseCase(_FakePlayerRepository(_players())),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        draftSelectionControllerProvider.notifier,
      );
      await notifier.loadPlayers(
        squadId: 'squad-1',
        initialSelectedIds: const ['p1', 'p2', 'p3'],
      );

      notifier.upsertTogetherGroup(playerIds: const ['p1', 'p2']);
      notifier.upsertAgainstGroup(playerIds: const ['p1', 'p2']);

      final message = notifier.validateSelection();
      expect(message, contains('tej samej relacji "Razem"'));
    },
  );
}

List<Player> _players() {
  return [
    Player(
      playerId: 'p1',
      squadId: 'squad-1',
      name: 'Adam',
      baseRanking: 50,
      ranking: 50,
      createdAt: DateTime(2026, 1, 1),
    ),
    Player(
      playerId: 'p2',
      squadId: 'squad-1',
      name: 'Bartek',
      baseRanking: 50,
      ranking: 50,
      createdAt: DateTime(2026, 1, 1),
    ),
    Player(
      playerId: 'p3',
      squadId: 'squad-1',
      name: 'Cezary',
      baseRanking: 50,
      ranking: 50,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
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
