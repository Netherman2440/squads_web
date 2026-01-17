import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/players_providers.dart';

class GetPlayerHeadToHeadStatsUseCase {
  final PlayerRepository _repository;

  GetPlayerHeadToHeadStatsUseCase(this._repository);

  Future<List<PlayerHeadToHeadStat>> execute({required String playerId}) {
    return _repository.getPlayerHeadToHeadStats(playerId: playerId);
  }
}

final getPlayerHeadToHeadStatsUseCaseProvider =
    Provider<GetPlayerHeadToHeadStatsUseCase>((ref) {
  return GetPlayerHeadToHeadStatsUseCase(ref.read(playerRepositoryProvider));
});
