import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/domain/entities/membership.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/domain/repositories/membership_repository.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

enum SquadFailureType {
  notFound,
  forbidden,
  unexpected,
}

class SquadFailure {
  final SquadFailureType type;
  final Object? cause;

  const SquadFailure._(this.type, [this.cause]);

  const SquadFailure.notFound() : this._(SquadFailureType.notFound);

  const SquadFailure.forbidden() : this._(SquadFailureType.forbidden);

  const SquadFailure.unexpected([Object? cause])
      : this._(SquadFailureType.unexpected, cause);
}

class GetSquadResult {
  final Squad? squad;
  final SquadFailure? failure;

  const GetSquadResult._({
    this.squad,
    this.failure,
  });

  const GetSquadResult.success(Squad squad)
      : this._(
          squad: squad,
          failure: null,
        );

  const GetSquadResult.error(SquadFailure failure)
      : this._(
          squad: null,
          failure: failure,
        );
}

class GetSquadUseCase {
  final SquadRepository _squadRepository;
  final MembershipRepository _membershipRepository;

  GetSquadUseCase(
    this._squadRepository,
    this._membershipRepository,
  );

  Future<GetSquadResult> execute({
    required String squadId,
    String? userId,
    bool isGuest = false,
  }) async {
    try {
      final squad = await _squadRepository.getSquad(squadId);

      if (squad == null) {
        return const GetSquadResult.error(SquadFailure.notFound());
      }

      if (isGuest || userId == null) {
        if (squad.visibility == SquadVisibility.private) {
          return const GetSquadResult.error(SquadFailure.forbidden());
        }

        return GetSquadResult.success(
          squad.copyWith(role: SquadRole.none),
        );
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
          return const GetSquadResult.error(SquadFailure.forbidden());
        }

        return GetSquadResult.success(
          squad.copyWith(role: SquadRole.none),
        );
      }

      return GetSquadResult.success(
        squad.copyWith(role: membership.role),
      );
    } catch (error) {
      return GetSquadResult.error(SquadFailure.unexpected(error));
    }
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


