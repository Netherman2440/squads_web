import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/tournaments/application/dto/tournament_details_dto.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';

class TournamentTeamStats {
  final String tournamentTeamId;
  final String teamName;
  final String? teamColor;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const TournamentTeamStats({
    required this.tournamentTeamId,
    required this.teamName,
    required this.teamColor,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  TournamentTeamStats copyWith({
    int? wins,
    int? draws,
    int? losses,
    int? goalsFor,
    int? goalsAgainst,
  }) {
    return TournamentTeamStats(
      tournamentTeamId: tournamentTeamId,
      teamName: teamName,
      teamColor: teamColor,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
    );
  }

  int get goalDifference => goalsFor - goalsAgainst;
  int get played => wins + draws + losses;

  TournamentStandingRow toStandingRow() {
    return TournamentStandingRow(
      tournamentTeamId: tournamentTeamId,
      teamName: teamName,
      teamColor: teamColor,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    );
  }
}

Map<String, TournamentTeamStats> computeTournamentTeamStats({
  required List<TournamentTeam> teams,
  required List<Match> matches,
}) {
  final stats = <String, TournamentTeamStats>{
    for (final team in teams)
      team.tournamentTeamId: TournamentTeamStats(
        tournamentTeamId: team.tournamentTeamId,
        teamName: _teamName(team),
        teamColor: team.color,
        wins: 0,
        draws: 0,
        losses: 0,
        goalsFor: 0,
        goalsAgainst: 0,
      ),
  };

  final teamsById = {for (final team in teams) team.tournamentTeamId: team};

  for (final match in matches) {
    final resolved = resolveTournamentTeamIds(match: match, teams: teamsById);
    if (resolved == null) {
      continue;
    }

    final homeScore = match.homeScore;
    final awayScore = match.awayScore;
    if (homeScore == null || awayScore == null) {
      continue;
    }

    final homeStats = stats[resolved.homeTeamId];
    final awayStats = stats[resolved.awayTeamId];
    if (homeStats == null || awayStats == null) {
      continue;
    }

    stats[resolved.homeTeamId] = homeStats.copyWith(
      goalsFor: homeStats.goalsFor + homeScore,
      goalsAgainst: homeStats.goalsAgainst + awayScore,
      wins: homeStats.wins + (homeScore > awayScore ? 1 : 0),
      draws: homeStats.draws + (homeScore == awayScore ? 1 : 0),
      losses: homeStats.losses + (homeScore < awayScore ? 1 : 0),
    );

    stats[resolved.awayTeamId] = awayStats.copyWith(
      goalsFor: awayStats.goalsFor + awayScore,
      goalsAgainst: awayStats.goalsAgainst + homeScore,
      wins: awayStats.wins + (awayScore > homeScore ? 1 : 0),
      draws: awayStats.draws + (awayScore == homeScore ? 1 : 0),
      losses: awayStats.losses + (awayScore < homeScore ? 1 : 0),
    );
  }

  return stats;
}

List<TournamentStandingRow> buildTournamentStandings({
  required List<TournamentTeam> teams,
  required List<Match> matches,
}) {
  final rows = computeTournamentTeamStats(
    teams: teams,
    matches: matches,
  ).values.map((stats) => stats.toStandingRow()).toList(growable: false);

  rows.sort((left, right) {
    final byPoints = right.points.compareTo(left.points);
    if (byPoints != 0) {
      return byPoints;
    }

    final byGoalDiff = right.goalDifference.compareTo(left.goalDifference);
    if (byGoalDiff != 0) {
      return byGoalDiff;
    }

    final byGoalsFor = right.goalsFor.compareTo(left.goalsFor);
    if (byGoalsFor != 0) {
      return byGoalsFor;
    }

    final byWins = right.wins.compareTo(left.wins);
    if (byWins != 0) {
      return byWins;
    }

    return left.teamName.toLowerCase().compareTo(right.teamName.toLowerCase());
  });

  return rows;
}

({String homeTeamId, String awayTeamId})? resolveTournamentTeamIds({
  required Match match,
  required Map<String, TournamentTeam> teams,
}) {
  final scoreMeta = match.scoreMeta;
  final homeId = scoreMeta['tournament_home_team_id'] as String?;
  final awayId = scoreMeta['tournament_away_team_id'] as String?;

  if (homeId != null && awayId != null) {
    return (homeTeamId: homeId, awayTeamId: awayId);
  }

  // Fallback for older rows without metadata.
  final homeName = match.homeTeam?.name?.trim().toLowerCase();
  final awayName = match.awayTeam?.name?.trim().toLowerCase();

  String? resolvedHomeId;
  String? resolvedAwayId;

  if (homeName != null && homeName.isNotEmpty) {
    for (final team in teams.values) {
      if (_teamName(team).trim().toLowerCase() == homeName) {
        resolvedHomeId = team.tournamentTeamId;
        break;
      }
    }
  }

  if (awayName != null && awayName.isNotEmpty) {
    for (final team in teams.values) {
      if (_teamName(team).trim().toLowerCase() == awayName) {
        resolvedAwayId = team.tournamentTeamId;
        break;
      }
    }
  }

  if (resolvedHomeId == null || resolvedAwayId == null) {
    return null;
  }

  return (homeTeamId: resolvedHomeId, awayTeamId: resolvedAwayId);
}

String _teamName(TournamentTeam team) {
  final name = team.name?.trim();
  if (name == null || name.isEmpty) {
    return 'Team';
  }
  return name;
}
