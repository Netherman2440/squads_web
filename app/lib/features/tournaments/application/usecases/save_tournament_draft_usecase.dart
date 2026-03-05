import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_draft_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class SaveTournamentDraftUseCase {
  final TournamentDraftRepository _repository;

  const SaveTournamentDraftUseCase(this._repository);

  Future<String> executeCompleted({
    required String squadId,
    required String tournamentId,
    required List<String> selectedPlayerIds,
    required int teamCount,
    required List<DraftRule> rules,
    required List<Draft> proposals,
    required Map<String, Map<String, double>> winRateMatrix,
    int? seed,
  }) {
    return _repository.createCompletedDraft(
      squadId: squadId,
      tournamentId: tournamentId,
      selectedPlayerIds: selectedPlayerIds,
      teamCount: teamCount,
      rules: rules,
      proposals: proposals,
      winRateMatrix: winRateMatrix,
      seed: seed,
    );
  }

  Future<String> executeError({
    required String squadId,
    required String tournamentId,
    required int teamCount,
    required String errorMessage,
  }) {
    return _repository.createErrorDraft(
      squadId: squadId,
      tournamentId: tournamentId,
      teamCount: teamCount,
      errorMessage: errorMessage,
    );
  }
}

final saveTournamentDraftUseCaseProvider = Provider<SaveTournamentDraftUseCase>(
  (ref) {
    return SaveTournamentDraftUseCase(
      ref.read(tournamentDraftRepositoryProvider),
    );
  },
);
