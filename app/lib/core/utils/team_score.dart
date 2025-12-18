/// Utilities for computing team scores consistently across the app.
///
/// When [playWithSubstitute] is enabled and team sizes are uneven (odd number
/// of total players), the larger team is adjusted as if one player sits out for
/// an equal share of the match.
///
/// Effective score formula for the larger team:
///
///   effective = totalScore * (m - 1) / m
///
/// where m is the size of the larger team.
double effectiveTeamScore({
  required double totalScore,
  required int teamSize,
  required int opponentTeamSize,
  required bool playWithSubstitute,
}) {
  if (!playWithSubstitute) {
    return totalScore;
  }

  if (teamSize <= 0) {
    return 0.0;
  }

  if (teamSize <= opponentTeamSize) {
    return totalScore;
  }

  final factor = (teamSize - 1) / teamSize;
  return totalScore * factor;
}
