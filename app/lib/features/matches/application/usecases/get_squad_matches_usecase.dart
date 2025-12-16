import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';

class GetSquadMatchesUseCase {
  const GetSquadMatchesUseCase(this._matchRepository);

  final MatchRepository _matchRepository;

  Future<List<Match>> execute({required String squadId}) {
    return _matchRepository.getSquadMatches(squadId: squadId);
  }
}

final getSquadMatchesUseCaseProvider = Provider<GetSquadMatchesUseCase>((ref) {
  final repository = ref.read(matchRepositoryProvider);
  return GetSquadMatchesUseCase(repository);
});
