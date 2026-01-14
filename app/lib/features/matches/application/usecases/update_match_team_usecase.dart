import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/entities/team.dart';
import 'package:app/features/matches/domain/repositories/team_repository.dart';
import 'package:app/features/matches/matches_providers.dart';

class UpdateMatchTeamUseCase {
  final TeamRepository _teamRepository;

  UpdateMatchTeamUseCase(this._teamRepository);

  Future<Team> execute({
    required String matchId,
    required String teamId,
    String? name,
    String? color,
  }) {
    return _teamRepository.updateTeam(
      matchId: matchId,
      teamId: teamId,
      name: name,
      color: color,
    );
  }
}

final updateMatchTeamUseCaseProvider = Provider<UpdateMatchTeamUseCase>((ref) {
  return UpdateMatchTeamUseCase(ref.read(teamRepositoryProvider));
});
