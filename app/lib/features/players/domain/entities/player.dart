class Player {
  final String id;
  final String squadId;
  final String name;
  final String? position;
  final int baseScore;
  final double score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Player({
    required this.id,
    required this.squadId,
    required this.name,
    required this.position,
    required this.baseScore,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  Player copyWith({
    String? id,
    String? squadId,
    String? name,
    String? position,
    int? baseScore,
    double? score,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Player(
      id: id ?? this.id,
      squadId: squadId ?? this.squadId,
      name: name ?? this.name,
      position: position ?? this.position,
      baseScore: baseScore ?? this.baseScore,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
