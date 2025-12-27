import 'package:app/features/players/domain/entities/player.dart';

class Draft {
  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final double homeTotalRanking;
  final double awayTotalRanking;

  const Draft({
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeTotalRanking,
    required this.awayTotalRanking,
  });
}
