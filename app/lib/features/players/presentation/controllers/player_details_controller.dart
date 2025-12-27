import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/ranking_history_entry.dart';
import '../../application/usecases/get_player_details_usecase.dart';
import '../../application/usecases/get_player_ranking_history_usecase.dart';

class PlayerDetailsState {
  final Player player;
  final List<RankingHistoryEntry> rankingHistory;

  PlayerDetailsState({
    required this.player,
    required this.rankingHistory,
  });
}

final playerDetailsProvider = FutureProvider.family<PlayerDetailsState, String>((ref, playerId) async {
  final getDetails = ref.read(getPlayerDetailsUseCaseProvider);
  final getHistory = ref.read(getPlayerRankingHistoryUseCaseProvider);

  final results = await Future.wait([
    getDetails.execute(playerId: playerId),
    getHistory.execute(playerId),
  ]);

  return PlayerDetailsState(
    player: results[0] as Player,
    rankingHistory: results[1] as List<RankingHistoryEntry>,
  );
});

