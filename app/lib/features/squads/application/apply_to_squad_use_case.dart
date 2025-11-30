import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

import '../domain/repositories/squad_repository.dart';

class ApplyToSquadUseCase {
  final SquadRepository _repository;

  ApplyToSquadUseCase(this._repository);

  Future<void> execute(String squadId, String userId) async {
    await _repository.applyToSquad(squadId, userId);
  }
}

final applyToSquadUseCaseProvider = Provider<ApplyToSquadUseCase>((ref) {
  final repository = ref.read(squadRepositoryProvider);
  return ApplyToSquadUseCase(repository);
});
