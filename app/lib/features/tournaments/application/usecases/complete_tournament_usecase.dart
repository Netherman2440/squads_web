import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/app_config.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/players_providers.dart';
import 'package:app/features/squads/application/get_squad_use_case.dart';
import 'package:app/features/tournaments/application/usecases/tournament_standings_calculator.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class CompleteTournamentUseCase {
  final TournamentRepository _tournamentRepository;
  final RankingRepository _rankingRepository;
  final PlayerRepository _playerRepository;
  final GetSquadUseCase _getSquadUseCase;

  const CompleteTournamentUseCase(
    this._tournamentRepository,
    this._rankingRepository,
    this._playerRepository,
    this._getSquadUseCase,
  );

  Future<void> execute({required String tournamentId}) async {
    final tournament = await _tournamentRepository.getTournament(
      tournamentId: tournamentId,
    );

    if (tournament.status == TournamentStatus.completed) {
      return;
    }

    final teams = await _tournamentRepository.getTournamentTeams(
      tournamentId: tournamentId,
    );
    final matches = await _tournamentRepository.getTournamentMatches(
      tournamentId: tournamentId,
    );
    final standings = computeTournamentTeamStats(teams: teams, matches: matches);

    final rankingEntries = await _rankingRepository.getTournamentRankingHistory(
      tournamentId,
    );

    final squad = await _getSquadUseCase.execute(squadId: tournament.squadId);

    if (rankingEntries.isNotEmpty && squad.rankingUpdate) {
      final playerTeam = <String, String>{
        for (final team in teams)
          for (final player in team.players) player.playerId: team.tournamentTeamId,
      };

      for (final entry in rankingEntries) {
        final teamId = playerTeam[entry.playerId];
        if (teamId == null) {
          continue;
        }

        final teamStats = standings[teamId];
        if (teamStats == null) {
          continue;
        }

        var newDelta = _computeTeamDelta(
          wins: teamStats.wins,
          losses: teamStats.losses,
          goalDifference: teamStats.goalDifference,
          rankingMultiplier: squad.rankingMultiplier,
        );

        if (squad.useExperienceFactor) {
          final history = await _rankingRepository.getPlayerRankingHistory(
            entry.playerId,
          );
          final matchesPlayed = history
              .where((historyEntry) => historyEntry.matchId != null)
              .length
              .clamp(1, AppConfig.maxMatchesPlayed);
          newDelta /= matchesPlayed;
        }

        final oldDelta = entry.change ?? 0.0;
        final expectedDiff = newDelta - oldDelta;
        if (expectedDiff == 0) {
          continue;
        }

        final player = await _playerRepository.getPlayer(playerId: entry.playerId);
        final desiredRanking = (player.ranking + expectedDiff)
            .clamp(0.0, 100.0)
            .toDouble();
        final adjustedDiff = desiredRanking - player.ranking;
        final adjustedNewDelta = oldDelta + adjustedDiff;

        if (adjustedNewDelta != oldDelta) {
          await _rankingRepository.updateTournamentRankingChange(
            playerId: entry.playerId,
            tournamentId: tournamentId,
            newDelta: adjustedNewDelta,
          );
        }

        if (adjustedDiff != 0) {
          await _playerRepository.updatePlayerRanking(
            playerId: entry.playerId,
            newRanking: desiredRanking,
          );
        }
      }
    }

    await _tournamentRepository.updateTournament(
      tournamentId: tournamentId,
      status: TournamentStatus.completed,
    );
  }
}

double _computeTeamDelta({
  required int wins,
  required int losses,
  required int goalDifference,
  required int rankingMultiplier,
}) {
  final matchBalance = (wins - losses).toDouble();
  final goalDiffFactor = goalDifference / 10.0;
  return (matchBalance + goalDiffFactor) * rankingMultiplier;
}

final completeTournamentUseCaseProvider = Provider<CompleteTournamentUseCase>(
  (ref) {
    return CompleteTournamentUseCase(
      ref.read(tournamentRepositoryProvider),
      ref.read(rankingRepositoryProvider),
      ref.read(playerRepositoryProvider),
      ref.read(getSquadUseCaseProvider),
    );
  },
);
