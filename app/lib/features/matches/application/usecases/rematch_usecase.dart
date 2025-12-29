import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/application/usecases/create_match_usecase.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';

class RematchUseCase {
  final MatchRepository _matchRepository;
  final CreateMatchUseCase _createMatchUseCase;

  RematchUseCase(this._matchRepository, this._createMatchUseCase);

  Future<Match> execute({required String matchId}) async {
    final match = await _matchRepository.getMatch(matchId: matchId);

    if (match.homeTeam == null || match.awayTeam == null) {
      throw Exception('Match teams are missing');
    }

    // Swap teams: Old Away becomes New Home, Old Home becomes New Away
    final newHomePlayerIds = match.awayTeam!.players
        .map((p) => p.playerId)
        .toList();
    final newAwayPlayerIds = match.homeTeam!.players
        .map((p) => p.playerId)
        .toList();

    return _createMatchUseCase.execute(
      squadId: match.squadId,
      tournamentId: match.tournamentId,
      homePlayerIds: newHomePlayerIds,
      awayPlayerIds: newAwayPlayerIds,
      // Swap names and colors too so the "Team" entity stays consistent with players
      homeTeamName: match.awayTeam!.name,
      homeTeamColor: match.awayTeam!.color,
      awayTeamName: match.homeTeam!.name,
      awayTeamColor: match.homeTeam!.color,
    );
  }
}

final rematchUseCaseProvider = Provider<RematchUseCase>((ref) {
  return RematchUseCase(
    ref.read(matchRepositoryProvider),
    ref.read(createMatchUseCaseProvider),
  );
});
