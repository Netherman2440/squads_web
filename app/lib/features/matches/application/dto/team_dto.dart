import 'package:app/features/matches/application/dto/player_dto.dart';
import 'package:app/features/matches/domain/entities/team.dart';

class TeamDto {
  final String teamId;
  final String matchId;
  final String? name;
  final String? color;
  final List<PlayerDto> players;

  const TeamDto({
    required this.teamId,
    required this.matchId,
    this.name,
    this.color,
    this.players = const [],
  });

  factory TeamDto.fromDomain(Team team) {
    return TeamDto(
      teamId: team.teamId,
      matchId: team.matchId,
      name: team.name,
      color: team.color,
      players: team.players.map(PlayerDto.fromDomain).toList(),
    );
  }
}
