import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

import '../domain/repositories/squad_repository.dart';

class UpdateSquadRankingSettingsUseCase {
  final SquadRepository _squadRepository;

  const UpdateSquadRankingSettingsUseCase(this._squadRepository);

  Future<void> execute({
    required String squadId,
    required bool rankingUpdate,
    required int rankingMultiplier,
    required bool useExperienceFactor,
  }) async {
    await _squadRepository.updateSquad(
      squadId,
      rankingUpdate: rankingUpdate,
      rankingMultiplier: rankingMultiplier,
      useExperienceFactor: useExperienceFactor,
    );
  }
}

final updateSquadRankingSettingsUseCaseProvider =
    Provider<UpdateSquadRankingSettingsUseCase>((ref) {
      final squadRepository = ref.read(squadRepositoryProvider);
      return UpdateSquadRankingSettingsUseCase(squadRepository);
    });
