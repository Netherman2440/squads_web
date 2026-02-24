import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/application/usecases/add_player_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';
import 'package:app/features/players/domain/entities/player_stats.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';

void main() {
  test('normalizes allowed position values before saving', () async {
    final repository = _FakePlayerRepository();
    final useCase = AddPlayerUseCase(repository);

    await useCase.execute(
      squadId: 'squad-1',
      name: 'Adam',
      position: 'midfielder',
      baseRanking: 50,
    );

    expect(repository.lastPosition, 'middlefielder');
  });

  test('rejects unsupported position values', () async {
    final repository = _FakePlayerRepository();
    final useCase = AddPlayerUseCase(repository);

    await expectLater(
      () => useCase.execute(
        squadId: 'squad-1',
        name: 'Adam',
        position: 'winger',
        baseRanking: 50,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}

class _FakePlayerRepository implements PlayerRepository {
  String? lastPosition;

  @override
  Future<Player> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseRanking,
  }) async {
    lastPosition = position;
    return Player(
      playerId: 'p1',
      squadId: squadId,
      name: name,
      position: position,
      baseRanking: baseRanking,
      ranking: baseRanking.toDouble(),
      createdAt: DateTime(2026, 1, 1),
    );
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
  Future<List<Player>> getSquadPlayers({required String squadId}) {
    throw UnimplementedError();
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
