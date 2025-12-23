import 'package:app/features/players/domain/entities/player.dart';

class Draft {
  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final double homeTotalScore;
  final double awayTotalScore;

  const Draft({
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeTotalScore,
    required this.awayTotalScore,
  });
}
