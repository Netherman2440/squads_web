import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/squad_repository.dart';

class ChangeSquadVisibilityUseCase {
  final SquadRepository _squadRepository;

  ChangeSquadVisibilityUseCase(this._squadRepository);

  Future<void> execute({
    required String squadId,
    required SquadVisibility newVisibility,
  }) async {
    await _squadRepository.updateSquad(squadId, visibility: newVisibility);
  }
}

final changeSquadVisibilityUseCaseProvider =
    Provider<ChangeSquadVisibilityUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  return ChangeSquadVisibilityUseCase(squadRepository);
});

