import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/matches_providers.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/players_providers.dart';

class GetPlayerMatchesUseCase {
  final RankingRepository _rankingRepository;
  final MatchRepository _matchRepository;

  GetPlayerMatchesUseCase(this._rankingRepository, this._matchRepository);

  Future<List<Match>> execute({required String playerId}) async {
    final history = await _rankingRepository.getPlayerRankingHistory(playerId);
    final matchIds = {
      for (final entry in history)
        if (entry.matchId != null) entry.matchId!,
    };

    if (matchIds.isEmpty) {
      return const [];
    }

    final matches = await _matchRepository.getMatches(
      matchIds: matchIds.toList(growable: false),
    );

    return matches;
  }
}

final getPlayerMatchesUseCaseProvider = Provider<GetPlayerMatchesUseCase>((ref) {
  return GetPlayerMatchesUseCase(
    ref.read(rankingRepositoryProvider),
    ref.read(matchRepositoryProvider),
  );
});
