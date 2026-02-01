import 'package:app/features/players/domain/entities/player.dart';

class PlayerDto {
  final String playerId;
  final String name;
  final double ranking;

  const PlayerDto({
    required this.playerId,
    required this.name,
    required this.ranking,
  });

  factory PlayerDto.fromDomain(Player player) {
    return PlayerDto(
      playerId: player.playerId,
      name: player.name,
      ranking: player.ranking,
    );
  }
}
