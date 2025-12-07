import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  CreateSquadUseCase(
    this._squadRepository,
    this._membershipRepository,
  );

  Future<void> execute({
    required String name,
    required SquadVisibility visibility,
    required String ownerId,
    required SportType sportType,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationFailure('Squad name cannot be empty');
    }

    final memberships =
        await _membershipRepository.getMembershipsForUser(ownerId);

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
  final squadRepository = ref.read(squadRepositoryProvider);
  final membershipRepository = ref.read(membershipRepositoryProvider);
  return CreateSquadUseCase(squadRepository, membershipRepository);
});
