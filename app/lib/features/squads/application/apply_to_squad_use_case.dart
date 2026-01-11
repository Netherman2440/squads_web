import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:app/core/error/failure.dart';

import '../domain/repositories/squad_repository.dart';

class ApplyToSquadUseCase {
  final SquadRepository _repository;
  final AuthEntity? _authEntity;

  ApplyToSquadUseCase(this._repository, this._authEntity);

  Future<void> execute(String squadId) async {
    final userId = _authEntity?.userId;
    final isGuest = _authEntity == null || _authEntity.isAnonymous;
    if (isGuest || userId == null) {
      throw const UnauthorizedFailure('Not authenticated.');
    }

    await _repository.applyToSquad(squadId, userId);
  }
}

final applyToSquadUseCaseProvider = Provider<ApplyToSquadUseCase>((ref) {
  final authEntity = ref.watch(authStateProvider).value;
  final repository = ref.read(squadRepositoryProvider);
  return ApplyToSquadUseCase(repository, authEntity);
});
