import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/domain/repositories/team_repository.dart';
import 'package:app/features/matches/matches_providers.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/players_providers.dart';

class UpdateMatchTeamsUseCase {
  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;
  final RankingRepository _rankingRepository;
  final PlayerRepository _playerRepository;

  UpdateMatchTeamsUseCase(
    this._matchRepository,
    this._teamRepository,
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

    // 2. Fetch current players (before update) to diff ranking history entries
    final currentTeams = await _teamRepository.getMatchTeams(matchId);
    final currentPlayers = [for (final team in currentTeams) ...team.players];
    final currentPlayerIds = currentPlayers.map((p) => p.playerId).toSet();

    // 3. Update teams
    await _teamRepository.updateMatchTeams(
      matchId: matchId,
      homePlayerIds: homePlayerIds,
      awayPlayerIds: awayPlayerIds,
    );

    await _matchRepository.refreshMatchWinProbability(matchId: matchId);

    final newPlayerIds = {...homePlayerIds, ...awayPlayerIds};

    // Identify Added Players
    final addedIds = newPlayerIds.difference(currentPlayerIds);
    if (addedIds.isNotEmpty) {
      final existingEntries = await Future.wait(
        addedIds.map(
          (id) async => MapEntry(
            id,
            await _rankingRepository.getRankingHistoryEntryByMatch(
              matchId: matchId,
              playerId: id,
            ),
          ),
        ),
      );
      final missingEntryIds = {
        for (final entry in existingEntries)
          if (entry.value == null) entry.key,
      };

      if (missingEntryIds.isNotEmpty) {
        final addedPlayersFutures = missingEntryIds.map(
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
    ref.read(teamRepositoryProvider),
    ref.read(rankingRepositoryProvider),
    ref.read(playerRepositoryProvider),
  );
});
