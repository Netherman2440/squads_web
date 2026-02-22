import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/stored_draft_payload.dart';
import 'package:app/features/draft/domain/repositories/draft_persistence_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/supabase_draft_persistence_repository.dart';

class GetMatchDraftUseCase {
  final DraftPersistenceRepository _repository;

  const GetMatchDraftUseCase(this._repository);

  Future<StoredDraftPayload?> execute({required String matchId}) {
    return _repository.getMatchDraft(matchId: matchId);
  }
}

final getMatchDraftUseCaseProvider = Provider<GetMatchDraftUseCase>((ref) {
  return GetMatchDraftUseCase(ref.read(draftPersistenceRepositoryProvider));
});
