class Player {
  final String playerId;
  final String squadId;
  final String name;
  final String? position;
  final int baseScore;
  final double score;
  final DateTime createdAt;


  const Player({
    required this.playerId,
    required this.squadId,
    required this.name,
    this.position,
    required this.baseScore,
    required this.score,
    required this.createdAt,
  });

  Player copyWith({
    String? playerId,
    String? squadId,
    String? name,
    String? position,
    int? baseScore,
    double? score,
    DateTime? createdAt,
  }) {
    return Player(
      playerId: playerId ?? this.playerId,
      squadId: squadId ?? this.squadId,
      name: name ?? this.name,
      position: position ?? this.position,
      baseScore: baseScore ?? this.baseScore,
      score: score ?? this.score,
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
      baseScore: map['base_score'] as int,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'squad_id': squadId,
      'name': name,
      'position': position,
      'base_score': baseScore,
      'score': score,
      'created_at': createdAt.toIso8601String(),
    };
  }
}


