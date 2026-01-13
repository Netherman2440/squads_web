import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcceptInviteUseCase {
  final SquadRepository _squadRepository;
  final AuthEntity? _authEntity;

  AcceptInviteUseCase(this._squadRepository, this._authEntity);

  Future<void> execute({required String squadId}) async {
    final userId = _authEntity?.userId;
    final isGuest = _authEntity == null || _authEntity.isAnonymous;
    if (isGuest || userId == null) {
      throw const UnauthorizedFailure('Not authenticated.');
    }

    await _squadRepository.addUserToSquad(squadId, userId);
  }
}

final acceptInviteUseCaseProvider = Provider<AcceptInviteUseCase>((ref) {
  final authEntity = ref.watch(authStateProvider).value;
  final squadRepository = ref.read(squadRepositoryProvider);
  return AcceptInviteUseCase(squadRepository, authEntity);
});
