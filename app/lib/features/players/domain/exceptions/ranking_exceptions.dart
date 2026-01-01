class RankingHistoryNotFoundException implements Exception {
  final String message;
  RankingHistoryNotFoundException(this.message);

  @override
  String toString() => 'RankingHistoryNotFoundException: $message';
}

class RankingUpdateConflictException implements Exception {
  final String message;
  RankingUpdateConflictException(this.message);

  @override
  String toString() => 'RankingUpdateConflictException: $message';
}
