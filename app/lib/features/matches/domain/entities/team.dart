import 'package:app/features/players/domain/entities/player.dart';

class Team {
  const Team({
    required this.teamId,
    required this.matchId,
    required this.side,
    this.name,
    this.color,
    this.players = const [],
  });

  final String teamId;
  final String matchId;
  final MatchSide side;
  final String? name;
  final String? color;
  final List<Player> players;

  factory Team.fromMap(Map<String, dynamic> map) {
    final playersData = map['team_players'] as List<dynamic>? ?? [];

    final players = playersData
        .map((playerMap) {
          final data = playerMap is Map
              ? Map<String, dynamic>.from(playerMap as Map)
              : <String, dynamic>{};
          final playerDetails = data['players'] ?? data['player'];

          if (playerDetails is Map) {
            return Player.fromMap(
              Map<String, dynamic>.from(playerDetails as Map),
            );
          }
          return null;
        })
        .whereType<Player>()
        .toList();

    return Team(
      teamId: map['team_id'] as String,
      matchId: map['match_id'] as String,
      side: MatchSideExtension.fromString(map['side'] as String?) ?? MatchSide.home,
      name: map['name'] as String?,
      color: map['color'] as String?,
      players: players,
    );
  }
}

enum MatchSide { home, away }

extension MatchSideExtension on MatchSide {
  static MatchSide? fromString(String? value) {
    if (value == null) {
      return null;
    }

    try {
      return MatchSide.values.firstWhere(
        (side) => side.name == value,
      );
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case MatchSide.home:
        return 'Home';
      case MatchSide.away:
        return 'Away';
    }
  }
}
