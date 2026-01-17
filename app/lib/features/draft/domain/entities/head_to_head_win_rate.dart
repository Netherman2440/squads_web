class HeadToHeadWinRate {
  final String playerId;
  final String oppPlayerId;
  final double winRate;

  const HeadToHeadWinRate({
    required this.playerId,
    required this.oppPlayerId,
    required this.winRate,
  });

  factory HeadToHeadWinRate.fromMap(Map<String, dynamic> map) {
    final value = map['win_rate'];
    return HeadToHeadWinRate(
      playerId: map['player_id'] as String,
      oppPlayerId: map['opp_player_id'] as String,
      winRate: value is num ? value.toDouble() : 0.5,
    );
  }
}
