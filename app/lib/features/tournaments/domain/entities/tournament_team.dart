import 'package:app/features/players/domain/entities/player.dart';

class TournamentTeam {
  final String tournamentTeamId;
  final String tournamentId;
  final String? name;
  final String? color;
  final DateTime createdAt;
  final List<Player> players;

  const TournamentTeam({
    required this.tournamentTeamId,
    required this.tournamentId,
    this.name,
    this.color,
    required this.createdAt,
    this.players = const [],
  });

  TournamentTeam copyWith({
    String? tournamentTeamId,
    String? tournamentId,
    String? name,
    String? color,
    DateTime? createdAt,
    List<Player>? players,
  }) {
    return TournamentTeam(
      tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
    );
  }

  factory TournamentTeam.fromMap(Map<String, dynamic> map) {
    return TournamentTeam(
      tournamentTeamId: map['tournament_team_id'] as String,
      tournamentId: map['tournament_id'] as String,
      name: map['name'] as String?,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class TournamentTeamInput {
  final String? tournamentTeamId;
  final String? name;
  final String? color;
  final List<String> playerIds;

  const TournamentTeamInput({
    this.tournamentTeamId,
    this.name,
    this.color,
    required this.playerIds,
  });
}
