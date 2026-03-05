import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/tournaments/domain/entities/tournament_draft.dart';

abstract class TournamentDraftRepository {
  Future<String> createCompletedDraft({
    required String squadId,
    required String tournamentId,
    required List<String> selectedPlayerIds,
    required int teamCount,
    required List<DraftRule> rules,
    required List<Draft> proposals,
    required Map<String, Map<String, double>> winRateMatrix,
    int? seed,
  });

  Future<String> createErrorDraft({
    required String squadId,
    required String tournamentId,
    required int teamCount,
    required String errorMessage,
  });

  Future<List<TournamentDraft>> getTournamentDrafts({
    required String tournamentId,
  });

  Future<TournamentDraft?> getTournamentDraft({
    required String tournamentDraftId,
  });

  Future<TournamentDraft?> getLatestTournamentDraft({
    required String tournamentId,
  });
}
