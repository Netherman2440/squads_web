import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/repositories/draft_persistence_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/supabase_draft_persistence_repository.dart';

class SaveMatchDraftUseCase {
  final DraftPersistenceRepository _repository;

  const SaveMatchDraftUseCase(this._repository);

  Future<void> executeCompleted({
    required String squadId,
    required String matchId,
    required List<Draft> proposals,
    required Map<String, Map<String, double>> winRateMatrix,
    required int teamCount,
  }) {
    return _repository.upsertCompletedDraft(
      squadId: squadId,
      matchId: matchId,
      proposals: proposals,
      winRateMatrix: winRateMatrix,
      teamCount: teamCount,
    );
  }

  Future<void> executeError({
    required String squadId,
    required String matchId,
    required int teamCount,
    required String errorMessage,
  }) {
    return _repository.upsertDraftError(
      squadId: squadId,
      matchId: matchId,
      teamCount: teamCount,
      errorMessage: errorMessage,
    );
  }
}

final saveMatchDraftUseCaseProvider = Provider<SaveMatchDraftUseCase>((ref) {
  return SaveMatchDraftUseCase(ref.read(draftPersistenceRepositoryProvider));
});
