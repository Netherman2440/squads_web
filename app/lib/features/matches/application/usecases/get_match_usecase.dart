import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/domain/repositories/team_repository.dart';
import 'package:app/features/matches/matches_providers.dart';

class GetMatchUseCase {
  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;

  GetMatchUseCase(this._matchRepository, this._teamRepository);

  Future<Match> execute({required String matchId}) async {
    // 1. Fetch Basic Match Info
    var match = await _matchRepository.getMatch(matchId: matchId);

    // 2. Fetch Teams using TeamRepository
    // This will fetch teams, players, and resolve historical ranking snapshots
    final teams = await _teamRepository.getMatchTeams(matchId);

    // 3. Assign teams to match
    // Note: getMatchTeams returns a list. We need to identify home/away.
    // Assuming Team entity has 'side' property.
    final homeTeam = teams.firstWhere(
      (t) => t.side.name == 'home',
      orElse: () => throw Exception('Home team missing'),
    );
    final awayTeam = teams.firstWhere(
      (t) => t.side.name == 'away',
      orElse: () => throw Exception('Away team missing'),
    );

    return match.copyWith(homeTeam: homeTeam, awayTeam: awayTeam);
  }
}

final getMatchUseCaseProvider = Provider<GetMatchUseCase>((ref) {
  return GetMatchUseCase(
    ref.read(matchRepositoryProvider),
    ref.read(teamRepositoryProvider),
  );
});
