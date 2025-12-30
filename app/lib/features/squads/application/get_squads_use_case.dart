import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/infrastructure/repositories/supabase_membership_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

import '../domain/entities/squad.dart';
import '../domain/repositories/membership_repository.dart';
import '../domain/repositories/squad_repository.dart';

class GetSquadsUseCase {
  final SquadRepository _squadRepository;
  final MembershipRepository _membershipRepository;

  GetSquadsUseCase(this._squadRepository, this._membershipRepository);

  Future<List<Squad>> execute({
    SquadVisibility? visibility,
    String? searchQuery,
    String? sportType,
    String? userId,
    bool isGuest = false,
  }) async {
    final squads = await _squadRepository.getSquads(
      visibility: visibility,
      searchQuery: searchQuery,
      sportType: sportType,
    );

    if (isGuest || userId == null) {
      return squads;
    }

    final memberships = await _membershipRepository.getMembershipsForUser(
      userId,
    );

    final roleMap = {
      for (final membership in memberships) membership.squadId: membership.role,
    };

    return squads
        .map(
          (squad) => squad.copyWith(role: roleMap[squad.squadId] ?? squad.role),
        )
        .toList();
  }
}

final getSquadsUseCaseProvider = Provider<GetSquadsUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  final membershipRepository = ref.read(membershipRepositoryProvider);
  return GetSquadsUseCase(squadRepository, membershipRepository);
});
