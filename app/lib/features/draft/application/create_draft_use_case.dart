import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/combinatory_draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

class CreateDraftUseCase {
  final DraftRepository _draftRepository;

  const CreateDraftUseCase(this._draftRepository);

  Future<List<Draft>> execute({
    required List<Player> players,
    int limit = 20,
    bool playWithSubstitute = true,
  }) async {
    return await _draftRepository.createDraft(
      players: players,
      limit: limit,
      playWithSubstitute: playWithSubstitute,
    );
  }
}

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return const CombinatoryDraftRepository();
});

final createDraftUseCaseProvider = Provider<CreateDraftUseCase>((ref) {
  final repository = ref.read(draftRepositoryProvider);
  return CreateDraftUseCase(repository);
});
