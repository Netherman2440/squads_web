import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/combinatory_draft_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/greedy_draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

class CreateDraftUseCase {
  final DraftRepository _draftRepository;

  const CreateDraftUseCase(this._draftRepository);

  Future<List<Draft>> execute({
    required List<Player> players,
    int teamCount = 2,
    List<DraftRule> rules = const [],
    int limit = 20,
    bool playWithSubstitute = true,
  }) async {
    return await _draftRepository.createDraft(
      players: players,
      teamCount: teamCount,
      rules: rules,
      limit: limit,
      playWithSubstitute: playWithSubstitute,
    );
  }
}

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return const CombinatoryDraftRepository();
});

final combinatoryDraftRepositoryProvider = Provider<DraftRepository>((ref) {
  return const CombinatoryDraftRepository();
});

final greedyDraftRepositoryProvider = Provider<DraftRepository>((ref) {
  return const GreedyDraftRepository();
});

final createDraftUseCaseProvider = Provider<CreateDraftUseCase>((ref) {
  final repository = ref.read(draftRepositoryProvider);
  return CreateDraftUseCase(repository);
});

final combinatoryCreateDraftUseCaseProvider = Provider<CreateDraftUseCase>((
  ref,
) {
  final repository = ref.read(combinatoryDraftRepositoryProvider);
  return CreateDraftUseCase(repository);
});

final greedyCreateDraftUseCaseProvider = Provider<CreateDraftUseCase>((ref) {
  final repository = ref.read(greedyDraftRepositoryProvider);
  return CreateDraftUseCase(repository);
});
