import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:app/core/error/failure.dart';

import '../domain/entities/squad.dart';
import '../domain/entities/user_squad_role.dart';
import '../domain/repositories/membership_repository.dart';
import '../domain/repositories/squad_repository.dart';

class CreateSquadUseCase {
  final SquadRepository _squadRepository;
  final MembershipRepository _membershipRepository;
  final AuthEntity? _authEntity;

  CreateSquadUseCase(
    this._squadRepository,
    this._membershipRepository,
    this._authEntity,
  );

  Future<void> execute({
    required String name,
    required SquadVisibility visibility,
    required SportType sportType,
  }) async {
    final ownerId = _authEntity?.userId;
    final isGuest = _authEntity == null || _authEntity.isAnonymous;
    if (isGuest || ownerId == null) {
      throw const UnauthorizedFailure('Not authenticated.');
    }

    if (name.trim().isEmpty) {
      throw const ValidationFailure('Squad name cannot be empty');
    }

    final memberships = await _membershipRepository.getMembershipsForUser(
      ownerId,
    );

    final ownsSquad = memberships.any(
      (membership) => membership.role == SquadRole.owner,
    );

    if (ownsSquad) {
      throw const ValidationFailure(
        'You can own only one squad. Please manage your existing squad.',
      );
    }

    await _squadRepository.createSquad(
      name.trim(),
      visibility,
      ownerId,
      sportType.name,
    );
  }
}

final createSquadUseCaseProvider = Provider<CreateSquadUseCase>((ref) {
  final authEntity = ref.watch(authStateProvider).value;
  final squadRepository = ref.read(squadRepositoryProvider);
  final membershipRepository = ref.read(membershipRepositoryProvider);
  return CreateSquadUseCase(squadRepository, membershipRepository, authEntity);
});
