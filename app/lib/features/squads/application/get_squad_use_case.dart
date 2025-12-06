import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/squads/domain/entities/membership.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/domain/repositories/membership_repository.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

class GetSquadUseCase {
  final SquadRepository _squadRepository;
  final MembershipRepository _membershipRepository;

  GetSquadUseCase(
    this._squadRepository,
    this._membershipRepository,
  );

  Future<Squad> execute({
    required String squadId,
    String? userId,
    bool isGuest = false,
  }) async {
      final squad = await _squadRepository.getSquad(squadId);

      if (squad == null) {
        throw const NotFoundFailure('Squad not found.');
      }

      if (isGuest || userId == null) {
        if (squad.visibility == SquadVisibility.private) {
          throw const UnauthorizedFailure('You do not have access to this squad.');
        }

        return squad.copyWith(role: SquadRole.none);
      }

      final memberships =
          await _membershipRepository.getMembershipsForUser(userId);

      final Membership membership = memberships.isEmpty
          ? Membership.empty()
          : memberships.firstWhere(
              (item) => item.squadId == squadId,
              orElse: () => Membership.empty(),
            );

      if (membership.isEmpty) {
        if (squad.visibility == SquadVisibility.private) {
          throw const UnauthorizedFailure('You do not have access to this squad.');
        }

        return squad.copyWith(role: SquadRole.none);
      }

      return squad.copyWith(role: membership.role);
  }
}

final getSquadUseCaseProvider = Provider<GetSquadUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  final membershipRepository = ref.read(membershipRepositoryProvider);

  return GetSquadUseCase(
    squadRepository,
    membershipRepository,
  );
});
