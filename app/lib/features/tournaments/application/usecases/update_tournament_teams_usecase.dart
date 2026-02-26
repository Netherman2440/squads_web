import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/players_providers.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class UpdateTournamentTeamsUseCase {
  final TournamentRepository _tournamentRepository;
  final RankingRepository _rankingRepository;

  const UpdateTournamentTeamsUseCase(
    this._tournamentRepository,
    this._rankingRepository,
  );

  Future<void> execute({
    required String tournamentId,
    required List<TournamentTeamInput> teams,
  }) async {
    if (teams.length < 2) {
      throw const ValidationFailure('Tournament requires at least 2 teams.');
    }

    final flattenedPlayerIds = <String>[];
    for (final team in teams) {
      if (team.playerIds.isEmpty) {
        throw const ValidationFailure('Each team must contain at least one player.');
      }
      flattenedPlayerIds.addAll(team.playerIds);
    }

    final uniquePlayerIds = flattenedPlayerIds.toSet();
    if (uniquePlayerIds.length != flattenedPlayerIds.length) {
      throw const ValidationFailure(
        'Each tournament player must belong to exactly one team.',
      );
    }

    final expectedPlayerIds = await _expectedTournamentPlayerIds(tournamentId);
    if (expectedPlayerIds.isNotEmpty) {
      if (uniquePlayerIds.length != expectedPlayerIds.length ||
          !uniquePlayerIds.containsAll(expectedPlayerIds)) {
        throw const ValidationFailure(
          'All tournament players must stay assigned to exactly one team.',
        );
      }
    }

    await _tournamentRepository.replaceTournamentTeams(
      tournamentId: tournamentId,
      teams: teams,
    );
  }

  Future<Set<String>> _expectedTournamentPlayerIds(String tournamentId) async {
    final rankingEntries = await _rankingRepository.getTournamentRankingHistory(
      tournamentId,
    );

    if (rankingEntries.isNotEmpty) {
      return rankingEntries.map((entry) => entry.playerId).toSet();
    }

    return (await _tournamentRepository.getTournamentPlayerIds(
      tournamentId: tournamentId,
    )).toSet();
  }
}

final updateTournamentTeamsUseCaseProvider =
    Provider<UpdateTournamentTeamsUseCase>((ref) {
      return UpdateTournamentTeamsUseCase(
        ref.read(tournamentRepositoryProvider),
        ref.read(rankingRepositoryProvider),
      );
    });
