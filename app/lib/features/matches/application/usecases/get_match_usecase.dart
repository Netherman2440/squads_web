import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';

class GetMatchUseCase {
  const GetMatchUseCase(this._matchRepository);

  final MatchRepository _matchRepository;

  Future<Match> execute({required String matchId}) {
    return _matchRepository.getMatch(matchId: matchId);
  }
}

final getMatchUseCaseProvider = Provider<GetMatchUseCase>((ref) {
  final repository = ref.read(matchRepositoryProvider);
  return GetMatchUseCase(repository);
});
