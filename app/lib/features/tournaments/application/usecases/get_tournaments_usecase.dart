import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class GetTournamentsUseCase {
  final TournamentRepository _repository;

  const GetTournamentsUseCase(this._repository);

  Future<List<Tournament>> execute({required String squadId}) {
    return _repository.getTournaments(squadId: squadId);
  }
}

final getTournamentsUseCaseProvider = Provider<GetTournamentsUseCase>((ref) {
  return GetTournamentsUseCase(ref.read(tournamentRepositoryProvider));
});
