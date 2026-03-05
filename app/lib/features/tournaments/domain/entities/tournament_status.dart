enum TournamentStatus { drafting, active, completed }

extension TournamentStatusParser on TournamentStatus {
  static TournamentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return TournamentStatus.active;
      case 'completed':
        return TournamentStatus.completed;
      case 'drafting':
      default:
        return TournamentStatus.drafting;
    }
  }
}
