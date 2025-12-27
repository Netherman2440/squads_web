import '../../domain/entities/ranking_history_entry.dart';
import '../../domain/repositories/ranking_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/supabase_ranking_repository.dart';

class GetPlayerRankingHistoryUseCase {
  final RankingRepository _rankingRepository;

  GetPlayerRankingHistoryUseCase(this._rankingRepository);

  Future<List<RankingHistoryEntry>> execute(String playerId) async {
    return await _rankingRepository.getPlayerRankingHistory(playerId);
  }
}

final getPlayerRankingHistoryUseCaseProvider = Provider<GetPlayerRankingHistoryUseCase>((ref) {
  final repository = ref.read(rankingRepositoryProvider);
  return GetPlayerRankingHistoryUseCase(repository);
});

