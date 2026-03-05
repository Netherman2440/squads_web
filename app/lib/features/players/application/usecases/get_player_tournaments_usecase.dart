import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class GetPlayerTournamentsUseCase {
  final TournamentRepository _tournamentRepository;

  GetPlayerTournamentsUseCase(this._tournamentRepository);

  Future<List<Tournament>> execute({
    required String squadId,
    required String playerId,
  }) async {
    final tournaments = await _tournamentRepository.getTournaments(
      squadId: squadId,
    );

    if (tournaments.isEmpty) {
      return const [];
    }

    final memberships = await Future.wait(
      tournaments.map((tournament) async {
        final playerIds = await _tournamentRepository.getTournamentPlayerIds(
          tournamentId: tournament.tournamentId,
        );
        return playerIds.contains(playerId);
      }),
    );

    return [
      for (var i = 0; i < tournaments.length; i += 1)
        if (memberships[i]) tournaments[i],
    ];
  }
}

final getPlayerTournamentsUseCaseProvider =
    Provider<GetPlayerTournamentsUseCase>((ref) {
      return GetPlayerTournamentsUseCase(
        ref.read(tournamentRepositoryProvider),
      );
    });
