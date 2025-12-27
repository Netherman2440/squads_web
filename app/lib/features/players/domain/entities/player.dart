class Player {
  final String playerId;
  final String squadId;
  final String name;
  final String? position;
  final int baseRanking;
  final double ranking;
  final DateTime createdAt;


  const Player({
    required this.playerId,
    required this.squadId,
    required this.name,
    this.position,
    required this.baseRanking,
    required this.ranking,
    required this.createdAt,
  });

  Player copyWith({
    String? playerId,
    String? squadId,
    String? name,
    String? position,
    int? baseRanking,
    double? ranking,
    DateTime? createdAt,
  }) {
    return Player(
      playerId: playerId ?? this.playerId,
      squadId: squadId ?? this.squadId,
      name: name ?? this.name,
      position: position ?? this.position,
      baseRanking: baseRanking ?? this.baseRanking,
      ranking: ranking ?? this.ranking,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at'] as String);

    return Player(
      playerId: map['player_id'] as String,
      squadId: map['squad_id'] as String,
      name: map['name'] as String,
      position: map['position'] as String?,
      baseRanking: map['base_score'] as int,
      ranking: (map['score'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'squad_id': squadId,
      'name': name,
      'position': position,
      'base_score': baseRanking,
      'score': ranking,
      'created_at': createdAt.toIso8601String(),
    };
  }
}


