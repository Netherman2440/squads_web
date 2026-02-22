import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/stored_draft_payload.dart';

abstract class DraftPersistenceRepository {
  Future<void> upsertCompletedDraft({
    required String squadId,
    required String matchId,
    required List<Draft> proposals,
    required Map<String, Map<String, double>> winRateMatrix,
    required int teamCount,
  });

  Future<void> upsertDraftError({
    required String squadId,
    required String matchId,
    required int teamCount,
    required String errorMessage,
  });

  Future<StoredDraftPayload?> getMatchDraft({required String matchId});
}
