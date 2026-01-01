import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/membership_repository.dart';

class ModifyMemberRoleUseCase {
  final MembershipRepository _membershipRepository;

  ModifyMemberRoleUseCase(this._membershipRepository);

  Future<void> execute({
    required String squadId,
    required String userId,
    required SquadRole newRole,
  }) async {
    // TODO: Add validation logic here (e.g. check permissions, validate transitions)
    // For now we assume the caller checks permissions.
    await _membershipRepository.updateMemberRole(squadId, userId, newRole);
  }
}

final modifyMemberRoleUseCaseProvider = Provider<ModifyMemberRoleUseCase>((
  ref,
) {
  final membershipRepository = ref.read(membershipRepositoryProvider);
  return ModifyMemberRoleUseCase(membershipRepository);
});
