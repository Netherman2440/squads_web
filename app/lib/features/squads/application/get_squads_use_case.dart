import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

import '../domain/entities/squad.dart';
import '../domain/repositories/squad_repository.dart';

class GetSquadsUseCase {
  final SquadRepository _repository;

  GetSquadsUseCase(this._repository);

  Future<List<Squad>> execute({
    SquadVisibility? visibility,
    String? searchQuery,
    String? sportType,
    String? userId,
    bool isGuest = false,
  }) async {
    final squads = await _repository.getSquads(
      visibility: visibility,
      searchQuery: searchQuery,
      sportType: sportType,
    );

    if (isGuest || userId == null) {
      return squads;
    }

    final userSquads = await _repository.getUserSquads(userId);
    final roleMap = {
      for (final squad in userSquads) squad.id: squad.role,
    };

    return squads
        .map(
          (squad) => squad.copyWith(
            role: roleMap[squad.id] ?? squad.role,
          ),
        )
        .toList();
  }
}

final getSquadsUseCaseProvider = Provider<GetSquadsUseCase>((ref) {
  final repository = ref.read(squadRepositoryProvider);
  return GetSquadsUseCase(repository);
});
