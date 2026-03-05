import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/tournaments/application/dto/tournament_details_dto.dart';
import 'package:app/features/tournaments/application/usecases/tournament_standings_calculator.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_draft_repository.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class GetTournamentUseCase {
  final TournamentRepository _tournamentRepository;
  final TournamentDraftRepository _tournamentDraftRepository;

  const GetTournamentUseCase(
    this._tournamentRepository,
    this._tournamentDraftRepository,
  );

  Future<TournamentDetailsDto> execute({required String tournamentId}) async {
    final tournament = await _tournamentRepository.getTournament(
      tournamentId: tournamentId,
    );

    final teams = await _tournamentRepository.getTournamentTeams(
      tournamentId: tournamentId,
    );

    final matches = await _tournamentRepository.getTournamentMatches(
      tournamentId: tournamentId,
    );

    final drafts = await _tournamentDraftRepository.getTournamentDrafts(
      tournamentId: tournamentId,
    );

    final standings = buildTournamentStandings(teams: teams, matches: matches);

    return TournamentDetailsDto(
      tournament: tournament,
      teams: teams,
      matches: matches,
      standings: standings,
      drafts: drafts,
    );
  }
}

final getTournamentUseCaseProvider = Provider<GetTournamentUseCase>((ref) {
  return GetTournamentUseCase(
    ref.read(tournamentRepositoryProvider),
    ref.read(tournamentDraftRepositoryProvider),
  );
});
