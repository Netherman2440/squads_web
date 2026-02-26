enum DraftAlgorithmSelection { combinatory, greedy }

class DraftAlgorithmPolicy {
  const DraftAlgorithmPolicy._();

  static DraftAlgorithmSelection resolve({
    required int teamCount,
    required int playerCount,
  }) {
    final threshold = switch (teamCount) {
      2 => 20,
      3 => 12,
      4 => 10,
      _ => 20,
    };

    if (playerCount >= threshold) {
      return DraftAlgorithmSelection.greedy;
    }

    return DraftAlgorithmSelection.combinatory;
  }
}
