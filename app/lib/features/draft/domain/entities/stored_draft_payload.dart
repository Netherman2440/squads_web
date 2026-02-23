class StoredDraftProposal {
  final List<List<String>> teams;

  const StoredDraftProposal({required this.teams});
}

class StoredDraftPayload {
  final String draftId;
  final String matchId;
  final int teamCount;
  final int proposalsCount;
  final int? seed;
  final String status;
  final String? errorMessage;
  final List<StoredDraftProposal> proposals;
  final Map<String, Map<String, double>> winRateMatrix;

  const StoredDraftPayload({
    required this.draftId,
    required this.matchId,
    required this.teamCount,
    required this.proposalsCount,
    required this.seed,
    required this.status,
    required this.errorMessage,
    required this.proposals,
    required this.winRateMatrix,
  });
}
