import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/application/usecases/get_player_head_to_head_stats_usecase.dart';
import 'package:app/features/players/application/usecases/get_player_stats_usecase.dart';
import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';
import 'package:app/features/players/domain/entities/player_stats.dart';

class PlayerStatsViewState {
  final PlayerStats stats;
  final List<PlayerHeadToHeadStat> headToHead;

  const PlayerStatsViewState({
    required this.stats,
    required this.headToHead,
  });
}

final playerStatsProvider =
    FutureProvider.family<PlayerStatsViewState, String>((ref, playerId) async {
  final statsUseCase = ref.read(getPlayerStatsUseCaseProvider);
  final headToHeadUseCase = ref.read(getPlayerHeadToHeadStatsUseCaseProvider);

  final results = await Future.wait([
    statsUseCase.execute(playerId: playerId),
    headToHeadUseCase.execute(playerId: playerId),
  ]);

  return PlayerStatsViewState(
    stats: results[0] as PlayerStats,
    headToHead: results[1] as List<PlayerHeadToHeadStat>,
  );
});
