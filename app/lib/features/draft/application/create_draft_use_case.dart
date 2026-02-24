import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/app_config.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/combinatory_draft_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/greedy_draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

class CreateDraftUseCase {
  final DraftRepository _draftRepository;
  final bool _enforceMaxPlayers;

  const CreateDraftUseCase(
    this._draftRepository, {
    bool enforceMaxPlayers = true,
  }) : _enforceMaxPlayers = enforceMaxPlayers;

  Future<List<Draft>> execute({
    required List<Player> players,
    int teamCount = 2,
    List<DraftRule> rules = const [],
    int limit = 20,
    bool playWithSubstitute = true,
    int? seed,
  }) async {
    if (_enforceMaxPlayers && players.length > AppConfig.maxPlayersPerMatch) {
      throw ValidationFailure(
        'Draft supports up to ${AppConfig.maxPlayersPerMatch} players per match.',
      );
    }

    return await _draftRepository.createDraft(
      players: players,
      teamCount: teamCount,
      rules: rules,
      limit: limit,
      playWithSubstitute: playWithSubstitute,
      seed: seed,
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
  return CreateDraftUseCase(repository, enforceMaxPlayers: true);
});

final combinatoryCreateDraftUseCaseProvider = Provider<CreateDraftUseCase>((
  ref,
) {
  final repository = ref.read(combinatoryDraftRepositoryProvider);
  return CreateDraftUseCase(repository, enforceMaxPlayers: true);
});

final greedyCreateDraftUseCaseProvider = Provider<CreateDraftUseCase>((ref) {
  final repository = ref.read(greedyDraftRepositoryProvider);
  return CreateDraftUseCase(repository, enforceMaxPlayers: false);
});
