import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

import '../domain/repositories/squad_repository.dart';

class DeleteSquadUseCase {
  final SquadRepository _squadRepository;

  const DeleteSquadUseCase(this._squadRepository);

  Future<void> execute({required String squadId}) async {
    await _squadRepository.deleteSquad(squadId);
  }
}

final deleteSquadUseCaseProvider = Provider<DeleteSquadUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  return DeleteSquadUseCase(squadRepository);
});
