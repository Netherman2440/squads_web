import '../../domain/repositories/ranking_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/supabase_ranking_repository.dart';

class UpdatePlayerRankingUseCase {
  final RankingRepository _rankingRepository;

  UpdatePlayerRankingUseCase(this._rankingRepository);

  Future<void> execute({
    required String playerId,
    required double newRanking,
  }) async {
    // Creates manual adjustment (matchId = null)
    await _rankingRepository.updatePlayerRanking(
      playerId: playerId,
      newRanking: newRanking,
      matchId: null,
    );
  }
}

final updatePlayerRankingUseCaseProvider = Provider<UpdatePlayerRankingUseCase>(
  (ref) {
    final repository = ref.read(rankingRepositoryProvider);
    return UpdatePlayerRankingUseCase(repository);
  },
);
