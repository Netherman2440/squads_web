import '../entities/player.dart';

abstract class PlayerRepository {
  Future<List<Player>> getSquadPlayers({required String squadId});

  Future<Player> getPlayer({required String playerId});

  Future<Player> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseRanking,
  });

  Future<void> deletePlayer({required String playerId});

  Future<Player> updatePlayer({
    required String playerId,
    String? name,
    String? position,
  });

  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
  });
}
