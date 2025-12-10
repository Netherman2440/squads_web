import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/players_remote_data_source.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl(this._remoteDataSource);

  final PlayersRemoteDataSource _remoteDataSource;

  @override
  Future<Player> addPlayer({
    required String squadId,
    required String name,
    String? position,
    required int baseScore,
  }) async {
    final model = await _remoteDataSource.addPlayer(
      squadId: squadId,
      name: name,
      position: position,
      baseScore: baseScore,
    );

    return model.toDomain();
  }

  @override
  Future<void> deletePlayer({required String playerId}) {
    return _remoteDataSource.deletePlayer(playerId);
  }

  @override
  Future<Player> getPlayer({required String playerId}) async {
    final model = await _remoteDataSource.getPlayer(playerId);
    return model.toDomain();
  }

  @override
  Future<List<Player>> getSquadPlayers({required String squadId}) async {
    final models = await _remoteDataSource.getPlayers(squadId);
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Player> updatePlayer({
    required String playerId,
    String? name,
    int? baseScore,
    double? score,
  }) async {
    final model = await _remoteDataSource.updatePlayer(
      playerId: playerId,
      name: name,
      baseScore: baseScore,
      score: score,
    );

    return model.toDomain();
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final remoteDataSource = ref.read(playersRemoteDataSourceProvider);
  return PlayerRepositoryImpl(remoteDataSource);
});
