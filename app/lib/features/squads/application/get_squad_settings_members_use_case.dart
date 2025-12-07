import 'package:app/features/squads/domain/entities/squad_member.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';
import 'package:app/features/users/domain/repositories/user_repository.dart';
import 'package:app/features/users/infrastructure/repositories/supabase_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/squad_repository.dart';

class GetSquadSettingsMembersUseCase {
  final SquadRepository _squadRepository;
  final UserRepository _userRepository;

  GetSquadSettingsMembersUseCase(
    this._squadRepository,
    this._userRepository,
  );

  Future<List<SquadMember>> execute(String squadId) async {
    final members = await _squadRepository.getSquadMembers(squadId);

    final userIds = members.map((m) => m.userId).toSet().toList();
    final users = await _userRepository.getUsers(userIds);
    final emailByUserId = {
      for (final user in users) user.id: user.email,
    };

    final enrichedMembers = members
        .map(
          (m) => SquadMember(
            squadId: m.squadId,
            role: m.role,
            userId: m.userId,
            email: emailByUserId[m.userId] ?? m.email,
          ),
        )
        .toList();

    // Filter out banned/removed if any (though currently repository fetches by squad_id which might include them based on schema,
    // usually soft-deletes are handled by repo or flags. Assuming removed rows are deleted or have 'removed' role).
    final activeMembers = enrichedMembers.where((m) =>
        m.role != SquadRole.removed &&
        m.role != SquadRole.none &&
        m.role != SquadRole.declined);

    // Sort: Pending > Owner > Admin > Member
    final sortedMembers = activeMembers.toList()..sort((a, b) {
      return _getRolePriority(a.role).compareTo(_getRolePriority(b.role));
    });

    return sortedMembers;
  }

  int _getRolePriority(SquadRole role) {
    switch (role) {
      case SquadRole.pending:
        return 0;
      case SquadRole.owner:
        return 1;
      case SquadRole.admin:
        return 2;
      case SquadRole.member:
        return 3;
      default:
        return 4;
    }
  }
}

final getSquadSettingsMembersUseCaseProvider =
    Provider<GetSquadSettingsMembersUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  final userRepository = ref.read(userRepositoryProvider);
  return GetSquadSettingsMembersUseCase(
    squadRepository,
    userRepository,
  );
});

