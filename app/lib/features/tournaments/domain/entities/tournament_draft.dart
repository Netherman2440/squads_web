import 'package:app/features/draft/domain/entities/draft_rule.dart';

class TournamentDraftProposal {
  final List<List<String>> teams;

  const TournamentDraftProposal({required this.teams});
}

class TournamentDraft {
  final String tournamentDraftId;
  final String tournamentId;
  final String squadId;
  final String status;
  final int teamCount;
  final int proposalsCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? seed;
  final List<String> selectedPlayerIds;
  final List<DraftRule> draftRules;
  final List<TournamentDraftProposal> proposals;
  final Map<String, Map<String, double>> winRateMatrix;

  const TournamentDraft({
    required this.tournamentDraftId,
    required this.tournamentId,
    required this.squadId,
    required this.status,
    required this.teamCount,
    required this.proposalsCount,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.seed,
    required this.selectedPlayerIds,
    required this.draftRules,
    required this.proposals,
    required this.winRateMatrix,
  });
}
