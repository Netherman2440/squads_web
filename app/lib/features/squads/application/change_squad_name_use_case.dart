import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/squad_repository.dart';

class ChangeSquadNameUseCase {
  final SquadRepository _squadRepository;

  ChangeSquadNameUseCase(this._squadRepository);

  Future<void> execute({
    required String squadId,
    required String newName,
  }) async {
    if (newName.trim().isEmpty) {
      // Could throw a specific domain failure here
      throw Exception('Squad name cannot be empty');
    }
    await _squadRepository.updateSquad(squadId, name: newName);
  }
}

final changeSquadNameUseCaseProvider = Provider<ChangeSquadNameUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  return ChangeSquadNameUseCase(squadRepository);
});

