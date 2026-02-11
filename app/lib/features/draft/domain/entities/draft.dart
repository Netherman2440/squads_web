import 'package:app/features/players/domain/entities/player.dart';

class DraftTeam {
  final int index;
  final List<Player> players;
  final double totalRanking;

  const DraftTeam({
    required this.index,
    required this.players,
    required this.totalRanking,
  });
}

class Draft {
  final List<DraftTeam> teams;

  const Draft({required this.teams});

  factory Draft.twoTeams({
    required List<Player> homePlayers,
    required List<Player> awayPlayers,
    required double homeTotalRanking,
    required double awayTotalRanking,
  }) {
    return Draft(
      teams: [
        DraftTeam(
          index: 0,
          players: homePlayers,
          totalRanking: homeTotalRanking,
        ),
        DraftTeam(
          index: 1,
          players: awayPlayers,
          totalRanking: awayTotalRanking,
        ),
      ],
    );
  }

  List<Player> get homePlayers =>
      teams.isNotEmpty ? teams.first.players : const <Player>[];
  List<Player> get awayPlayers =>
      teams.length > 1 ? teams[1].players : const <Player>[];
  double get homeTotalRanking =>
      teams.isNotEmpty ? teams.first.totalRanking : 0.0;
  double get awayTotalRanking => teams.length > 1 ? teams[1].totalRanking : 0.0;
}
