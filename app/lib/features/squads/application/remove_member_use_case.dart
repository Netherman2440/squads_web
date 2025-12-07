import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/membership_repository.dart';

class RemoveMemberUseCase {
  final MembershipRepository _membershipRepository;

  RemoveMemberUseCase(this._membershipRepository);

  Future<void> execute({
    required String squadId,
    required String userId,
  }) async {
    // TODO: Add validation logic here (e.g. check permissions)
    await _membershipRepository.updateMemberRole(squadId, userId, SquadRole.removed);
  }
}

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  final membershipRepository = ref.read(membershipRepositoryProvider);
  return RemoveMemberUseCase(membershipRepository);
});

