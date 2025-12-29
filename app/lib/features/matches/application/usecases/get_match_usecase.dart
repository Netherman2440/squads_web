import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';

class GetMatchUseCase {
  final MatchRepository _repository;

  GetMatchUseCase(this._repository);

  Future<Match> execute({required String matchId}) {
    return _repository.getMatch(matchId: matchId);
  }
}

final getMatchUseCaseProvider = Provider<GetMatchUseCase>((ref) {
  return GetMatchUseCase(ref.read(matchRepositoryProvider));
});

