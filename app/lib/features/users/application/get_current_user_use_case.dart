import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/domain/repositories/membership_repository.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';
import 'package:app/features/users/application/user_profile_summary.dart';
import 'package:app/features/users/domain/repositories/user_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:app/features/users/infrastructure/repositories/supabase_user_repository.dart';

class GetCurrentUserUseCase {
  final UserRepository _userRepository;
  final MembershipRepository _membershipRepository;
  final SquadRepository _squadRepository;

  const GetCurrentUserUseCase(
    this._userRepository,
    this._membershipRepository,
    this._squadRepository,
  );

  Future<UserProfileSummary?> execute() async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) {
      return null;
    }

    final memberships =
        await _membershipRepository.getMembershipsForUser(user.id);

    if (memberships.isEmpty) {
      return UserProfileSummary(user: user, memberships: const []);
    }

    final squadIds = memberships.map((m) => m.squadId).toSet().toList();
    final squads = await _squadRepository.getSquadsByIds(squadIds);
    final squadMap = {
      for (final squad in squads) squad.squadId: squad,
    };

    final items = memberships
        .map((membership) {
          final squad = squadMap[membership.squadId];
          if (squad == null) {
            return null;
          }

          return UserMembershipItem(
            squadId: squad.squadId,
            squadName: squad.name,
            role: membership.role,
          );
        })
        .whereType<UserMembershipItem>()
        .toList();

    return UserProfileSummary(
      user: user,
      memberships: items,
    );
  }
}

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final userRepository = ref.read(userRepositoryProvider);
  final membershipRepository = ref.read(membershipRepositoryProvider);
  final squadRepository = ref.read(squadRepositoryProvider);
  return GetCurrentUserUseCase(
    userRepository,
    membershipRepository,
    squadRepository,
  );
});

