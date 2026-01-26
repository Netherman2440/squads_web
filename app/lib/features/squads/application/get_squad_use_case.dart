import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
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
  final AuthEntity? _authEntity;
  final Logger _logger = Logger('GetSquadUseCase');

  GetSquadUseCase(
    this._squadRepository,
    this._membershipRepository,
    this._authEntity,
  );

  Future<Squad> execute({required String squadId}) async {
    final userId = _authEntity?.userId;
    final isGuest = _authEntity == null || _authEntity.isAnonymous;

    try {
      _logger.fine(
        'Fetching squad $squadId for userId=$userId, isGuest=$isGuest',
      );

      final squad = await _squadRepository.getSquad(squadId);

      if (squad == null) {
        _logger.warning('Squad $squadId not found');
        throw const NotFoundFailure('Squad not found.');
      }

      _logger.fine(
        'Squad $squadId fetched, ownerId=${squad.ownerId}, visibility=${squad.visibility}',
      );
      // Owner fallback: even if membership row is missing or inconsistent,
      // the owner from squads table always has access and role owner.
      if (squad.ownerId == userId) {
        _logger.fine(
          'User $userId is owner of squad $squadId (ownerId match).',
        );
        final withRole = squad.copyWith(role: SquadRole.owner);
        final withPending = await _withPendingFlag(withRole);
        return withPending;
      }
      if (isGuest) {
        if (squad.visibility == SquadVisibility.private) {
          _logger.warning(
            'Access denied to private squad $squadId for guest user.',
          );
          throw const UnauthorizedFailure(
            'You do not have access to this squad.',
          );
        }
        _logger.fine('User $userId is guest of squad $squadId (isGuest=true).');
        return squad.copyWith(role: SquadRole.guest);
      }

      if (userId == null) {
        throw const UnauthorizedFailure('Not authenticated.');
      }

      final memberships = await _membershipRepository.getMembershipsForUser(
        userId,
      );

      _logger.fine(
        'User $userId has ${memberships.length} memberships; '
        'searching for squad $squadId.',
      );

      final Membership membership = memberships.isEmpty
          ? Membership.empty()
          : memberships.firstWhere(
              (item) => item.squadId == squadId,
              orElse: () => Membership.empty(),
            );

      final role = membership.isEmpty ? SquadRole.none : membership.role;

      if (squad.visibility == SquadVisibility.public) {
        _logger.fine(
          'Public squad $squadId; returning role=$role for user $userId.',
        );
        return squad.copyWith(role: role);
      }

      if (membership.isEmpty) {
        _logger.warning(
          'Access denied to private squad $squadId for user $userId (no membership).',
        );
        throw const UnauthorizedFailure(
          'You do not have access to this squad.',
        );
      }

      final allowed =
          role == SquadRole.owner ||
          role == SquadRole.admin ||
          role == SquadRole.member;

      if (!allowed) {
        _logger.warning(
          'Access denied to private squad $squadId for user $userId with role=$role.',
        );
        throw const UnauthorizedFailure(
          'You do not have access to this squad.',
        );
      }

      final result = squad.copyWith(role: role);
      _logger.fine(
        'Returning squad $squadId for user $userId with role=${result.role}.',
      );
      return result;
    } catch (e, stack) {
      _logger.severe(
        'Failed to get squad $squadId for userId=$userId, isGuest=$isGuest',
        e,
        stack,
      );
      rethrow;
    }
  }

  Future<Squad> _withPendingFlag(Squad squad) async {
    if (squad.role != SquadRole.owner) {
      return squad;
    }

    try {
      final memberships = await _membershipRepository.getMembershipsForSquad(
        squad.squadId,
      );
      final hasPending = memberships.any((m) => m.role == SquadRole.pending);

      _logger.fine('Squad ${squad.squadId} hasPendingMembers=$hasPending');
      return squad.copyWith(hasPendingMembers: hasPending);
    } catch (e, stack) {
      _logger.warning(
        'Failed to compute hasPendingMembers for squad ${squad.squadId}',
        e,
        stack,
      );
      return squad;
    }
  }
}

final getSquadUseCaseProvider = Provider<GetSquadUseCase>((ref) {
  final authEntity = ref.watch(authStateProvider).value;
  final squadRepository = ref.read(squadRepositoryProvider);
  final membershipRepository = ref.read(membershipRepositoryProvider);

  return GetSquadUseCase(squadRepository, membershipRepository, authEntity);
});
