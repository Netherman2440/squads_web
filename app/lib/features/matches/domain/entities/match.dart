import 'package:app/features/matches/domain/entities/team.dart';
import 'package:app/features/matches/domain/entities/match_score_type.dart';

class Match {
  const Match({
    required this.matchId,
    required this.squadId,
    this.tournamentId,
    this.scoreType,
    this.homeScore,
    this.awayScore,
    this.scoreMeta = const {},
    required this.createdAt,
    this.homeTeam,
    this.awayTeam,
  });

  final String matchId;
  final String squadId;
  final String? tournamentId;
  final MatchScoreType? scoreType;
  final int? homeScore;
  final int? awayScore;
  final Map<String, dynamic> scoreMeta;
  final DateTime createdAt;
  final Team? homeTeam;
  final Team? awayTeam;

  factory Match.fromMap(Map<String, dynamic> map) {
    final teamsData = map['teams'] as List<dynamic>?;

    Team? homeTeam;
    Team? awayTeam;

    if (teamsData != null) {
      for (final teamMap in teamsData) {
        final team = Team.fromMap(Map<String, dynamic>.from(teamMap as Map));
        if (team.side == MatchSide.home) {
          homeTeam = team;
        } else if (team.side == MatchSide.away) {
          awayTeam = team;
        }
      }
    }

    return Match(
      matchId: map['match_id'] as String,
      squadId: map['squad_id'] as String,
      tournamentId: map['tournament_id'] as String?,
      scoreType: MatchScoreTypeExtension.fromString(map['score_type'] as String?),
      homeScore: map['home_score'] as int?,
      awayScore: map['away_score'] as int?,
      scoreMeta:
          Map<String, dynamic>.from(map['score_meta'] as Map? ?? <String, dynamic>{}),
      createdAt: DateTime.parse(map['created_at'] as String),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }
}
