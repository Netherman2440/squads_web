import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/entities/tournament_draft.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';

class TournamentStandingRow {
  final String tournamentTeamId;
  final String teamName;
  final String? teamColor;
  final int wins;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const TournamentStandingRow({
    required this.tournamentTeamId,
    required this.teamName,
    this.teamColor,
    required this.wins,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  int get goalDifference => goalsFor - goalsAgainst;
  int get played => wins + losses;
}

class TournamentDetailsDto {
  final Tournament tournament;
  final List<TournamentTeam> teams;
  final List<Match> matches;
  final List<TournamentStandingRow> standings;
  final List<TournamentDraft> drafts;

  const TournamentDetailsDto({
    required this.tournament,
    required this.teams,
    required this.matches,
    required this.standings,
    required this.drafts,
  });
}
