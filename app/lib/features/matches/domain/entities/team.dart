import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/matches/domain/entities/match_enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'team.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Team {
  final String teamId;
  final String matchId;
  final Side side;
  final String? name;
  final String? color;
  // Populated in list queries (without loading players) to detect empty teams.
  final int playerCount;
  @JsonKey(fromJson: _playersFromJson, toJson: _playersToJson)
  final List<Player> players;

  const Team({
    required this.teamId,
    required this.matchId,
    required this.side,
    this.name,
    this.color,
    this.playerCount = 0,
    this.players = const [],
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);

  Team copyWith({
    String? teamId,
    String? matchId,
    Side? side,
    String? name,
    String? color,
    int? playerCount,
    List<Player>? players,
  }) {
    return Team(
      teamId: teamId ?? this.teamId,
      matchId: matchId ?? this.matchId,
      side: side ?? this.side,
      name: name ?? this.name,
      color: color ?? this.color,
      playerCount: playerCount ?? this.playerCount,
      players: players ?? this.players,
    );
  }
}

List<Player> _playersFromJson(List<dynamic> json) =>
    json.map((e) => Player.fromMap(e as Map<String, dynamic>)).toList();

List<dynamic> _playersToJson(List<Player> players) =>
    players.map((e) => e.toMap()).toList();
