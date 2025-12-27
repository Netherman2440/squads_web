/// Utilities for computing team rankings consistently across the app.
///
/// When [playWithSubstitute] is enabled and team sizes are uneven (odd number
/// of total players), the larger team is adjusted as if one player sits out for
/// an equal share of the match.
///
/// Effective ranking formula for the larger team:
///
///   effective = totalRanking * (m - 1) / m
///
/// where m is the size of the larger team.
double effectiveTeamRanking({
  required double totalRanking,
  required int teamSize,
  required int opponentTeamSize,
  required bool playWithSubstitute,
}) {
  if (!playWithSubstitute) {
    return totalRanking;
  }

  if (teamSize <= 0) {
    return 0.0;
  }

  if (teamSize <= opponentTeamSize) {
    return totalRanking;
  }

  final factor = (teamSize - 1) / teamSize;
  return totalRanking * factor;
}
