import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_ranking_repository.dart';

class DeleteMatchUseCase {
  final MatchRepository _matchRepository;
  final RankingRepository _rankingRepository;

  DeleteMatchUseCase(this._matchRepository, this._rankingRepository);

  Future<void> execute({required String matchId}) async {
    // 1. Get Match to find players
    final match = await _matchRepository.getMatch(matchId: matchId);

    // 2. Revert and delete ranking history for all players
    final futures = <Future>[];

    if (match.homeTeam != null) {
      for (final p in match.homeTeam!.players) {
        futures.add(
          _rankingRepository.deleteMatchRankingEntry(
            playerId: p.playerId,
            matchId: matchId,
          ),
        );
      }
    }

    if (match.awayTeam != null) {
      for (final p in match.awayTeam!.players) {
        futures.add(
          _rankingRepository.deleteMatchRankingEntry(
            playerId: p.playerId,
            matchId: matchId,
          ),
        );
      }
    }

    await Future.wait(futures);

    // 3. Delete Match
    await _matchRepository.deleteMatch(matchId: matchId);
  }
}

final deleteMatchUseCaseProvider = Provider<DeleteMatchUseCase>((ref) {
  return DeleteMatchUseCase(
    ref.read(matchRepositoryProvider),
    ref.read(rankingRepositoryProvider),
  );
});
