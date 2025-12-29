import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/domain/repositories/team_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_team_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_ranking_repository.dart';

class DeleteMatchUseCase {
  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;
  final RankingRepository _rankingRepository;

  DeleteMatchUseCase(
    this._matchRepository,
    this._teamRepository,
    this._rankingRepository,
  );

  Future<void> execute({required String matchId}) async {
    // 1. Get teams to find players
    final teams = await _teamRepository.getMatchTeams(matchId);

    // 2. Revert and delete ranking history for all players
    final futures = <Future>[];

    for (final team in teams) {
      for (final p in team.players) {
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
    ref.read(teamRepositoryProvider),
    ref.read(rankingRepositoryProvider),
  );
});
