import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/players_providers.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class DeleteTournamentUseCase {
  final TournamentRepository _tournamentRepository;
  final RankingRepository _rankingRepository;

  const DeleteTournamentUseCase(
    this._tournamentRepository,
    this._rankingRepository,
  );

  Future<void> execute({required String tournamentId}) async {
    final rankingEntries = await _rankingRepository.getTournamentRankingHistory(
      tournamentId,
    );

    await Future.wait(
      rankingEntries.map(
        (entry) => _rankingRepository.deleteTournamentRankingEntry(
          playerId: entry.playerId,
          tournamentId: tournamentId,
        ),
      ),
    );

    await _tournamentRepository.deleteTournament(tournamentId: tournamentId);
  }
}

final deleteTournamentUseCaseProvider = Provider<DeleteTournamentUseCase>((
  ref,
) {
  return DeleteTournamentUseCase(
    ref.read(tournamentRepositoryProvider),
    ref.read(rankingRepositoryProvider),
  );
});
