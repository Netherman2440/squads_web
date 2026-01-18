import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/domain/entities/player_stats.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/players_providers.dart';

class GetPlayerStatsUseCase {
  final PlayerRepository _repository;

  GetPlayerStatsUseCase(this._repository);

  Future<PlayerStats> execute({required String playerId}) {
    return _repository.getPlayerStats(playerId: playerId);
  }
}

final getPlayerStatsUseCaseProvider = Provider<GetPlayerStatsUseCase>((ref) {
  return GetPlayerStatsUseCase(ref.read(playerRepositoryProvider));
});
