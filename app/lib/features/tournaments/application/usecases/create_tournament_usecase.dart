import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/players_providers.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class CreateTournamentUseCase {
  final TournamentRepository _tournamentRepository;
  final RankingRepository _rankingRepository;
  final PlayerRepository _playerRepository;

  const CreateTournamentUseCase(
    this._tournamentRepository,
    this._rankingRepository,
    this._playerRepository,
  );

  Future<Tournament> execute({
    required String squadId,
    required List<String> playerIds,
    String? name,
  }) async {
    final distinctPlayerIds = playerIds.toSet().toList(growable: false);
    if (distinctPlayerIds.length < 2) {
      throw const ValidationFailure(
        'Tournament requires at least 2 selected players.',
      );
    }

    final tournament = await _tournamentRepository.createTournament(
      squadId: squadId,
      name: name,
    );

    final players = await Future.wait(
      distinctPlayerIds.map(
        (playerId) => _playerRepository.getPlayer(playerId: playerId),
      ),
    );

    await Future.wait(
      players.map(
        (player) => _rankingRepository.createTournamentRankingEntry(
          playerId: player.playerId,
          tournamentId: tournament.tournamentId,
          currentRanking: player.ranking,
        ),
      ),
    );

    return tournament;
  }
}

final createTournamentUseCaseProvider = Provider<CreateTournamentUseCase>((ref) {
  return CreateTournamentUseCase(
    ref.read(tournamentRepositoryProvider),
    ref.read(rankingRepositoryProvider),
    ref.read(playerRepositoryProvider),
  );
});
