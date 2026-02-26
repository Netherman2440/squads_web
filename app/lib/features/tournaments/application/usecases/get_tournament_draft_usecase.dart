import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/tournaments/domain/entities/tournament_draft.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_draft_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class GetTournamentDraftUseCase {
  final TournamentDraftRepository _repository;

  const GetTournamentDraftUseCase(this._repository);

  Future<TournamentDraft?> execute({required String tournamentDraftId}) {
    return _repository.getTournamentDraft(
      tournamentDraftId: tournamentDraftId,
    );
  }

  Future<TournamentDraft?> executeLatest({required String tournamentId}) {
    return _repository.getLatestTournamentDraft(tournamentId: tournamentId);
  }
}

final getTournamentDraftUseCaseProvider = Provider<GetTournamentDraftUseCase>(
  (ref) {
    return GetTournamentDraftUseCase(ref.read(tournamentDraftRepositoryProvider));
  },
);
