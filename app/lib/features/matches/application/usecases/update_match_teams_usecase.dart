import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_ranking_repository.dart';

class UpdateMatchTeamsUseCase {
  final MatchRepository _matchRepository;
  final RankingRepository _rankingRepository;
  final PlayerRepository _playerRepository;

  UpdateMatchTeamsUseCase(
    this._matchRepository,
    this._rankingRepository,
    this._playerRepository,
  );

  Future<void> execute({
    required String matchId,
    required List<String> homePlayerIds,
    required List<String> awayPlayerIds,
  }) async {
    // 1. Get current match
    final match = await _matchRepository.getMatch(matchId: matchId);

    // Check if match has score
    if (match.homeScore != null || match.awayScore != null) {
      throw Exception('Cannot update teams for a match with score');
    }

    // 2. Update teams in MatchRepo
    await _matchRepository.updateMatchTeams(
      matchId: matchId,
      homePlayerIds: homePlayerIds,
      awayPlayerIds: awayPlayerIds,
    );

    // 3. Handle Ranking History entries
    if (match.homeTeam == null || match.awayTeam == null) {
      // Should not happen if getMatch returns full details, but safety check.
      return;
    }
    final currentPlayers = [
      ...match.homeTeam!.players,
      ...match.awayTeam!.players,
    ];
    final currentPlayerIds = currentPlayers.map((p) => p.playerId).toSet();
    final newPlayerIds = {...homePlayerIds, ...awayPlayerIds};

    // Identify Added Players
    final addedIds = newPlayerIds.difference(currentPlayerIds);
    if (addedIds.isNotEmpty) {
      final addedPlayersFutures = addedIds.map(
        (id) => _playerRepository.getPlayer(playerId: id),
      );
      final addedPlayers = await Future.wait(addedPlayersFutures);

      final createEntryFutures = addedPlayers.map((player) {
        return _rankingRepository.createMatchRankingEntry(
          playerId: player.playerId,
          matchId: matchId,
          currentRanking: player.ranking,
        );
      });
      await Future.wait(createEntryFutures);
    }

    // Identify Removed Players
    final removedIds = currentPlayerIds.difference(newPlayerIds);
    if (removedIds.isNotEmpty) {
      final removeEntryFutures = removedIds.map((id) {
        return _rankingRepository.deleteMatchRankingEntry(
          playerId: id,
          matchId: matchId,
        );
      });
      await Future.wait(removeEntryFutures);
    }
  }
}

final updateMatchTeamsUseCaseProvider = Provider<UpdateMatchTeamsUseCase>((
  ref,
) {
  return UpdateMatchTeamsUseCase(
    ref.read(matchRepositoryProvider),
    ref.read(rankingRepositoryProvider),
    ref.read(playerRepositoryProvider),
  );
});
