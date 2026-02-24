import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/application/usecases/update_player_position_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';
import 'package:app/features/players/domain/entities/player_stats.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';

void main() {
  test('normalizes allowed position values before updating', () async {
    final repository = _FakePlayerRepository();
    final useCase = UpdatePlayerPositionUseCase(repository);

    await useCase.execute(playerId: 'p1', newPosition: 'midfielder');

    expect(repository.lastPosition, 'middlefielder');
  });

  test('allows clearing position', () async {
    final repository = _FakePlayerRepository();
    final useCase = UpdatePlayerPositionUseCase(repository);

    await useCase.execute(playerId: 'p1', newPosition: null);

    expect(repository.lastPosition, isNull);
  });

  test('rejects unsupported position values', () async {
    final repository = _FakePlayerRepository();
    final useCase = UpdatePlayerPositionUseCase(repository);

    await expectLater(
      () => useCase.execute(playerId: 'p1', newPosition: 'winger'),
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
  Future<List<Player>> getSquadPlayers({required String squadId}) {
    throw UnimplementedError();
  }

  @override
  Future<Player> updatePlayer({
    required String playerId,
    String? name,
    String? position,
  }) async {
    lastPosition = position;
    return Player(
      playerId: playerId,
      squadId: 'squad-1',
      name: 'Adam',
      position: position,
      baseRanking: 50,
      ranking: 50,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
  }) {
    throw UnimplementedError();
  }
}
