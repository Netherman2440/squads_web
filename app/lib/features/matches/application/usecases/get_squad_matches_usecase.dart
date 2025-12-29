import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';

class GetSquadMatchesUseCase {
  final MatchRepository _repository;

  GetSquadMatchesUseCase(this._repository);

  Future<List<Match>> execute({required String squadId}) {
    return _repository.getSquadMatches(squadId: squadId);
  }
}

final getSquadMatchesUseCaseProvider = Provider<GetSquadMatchesUseCase>((ref) {
  return GetSquadMatchesUseCase(ref.read(matchRepositoryProvider));
});

