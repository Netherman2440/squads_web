import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/application/dto/match_details_dto.dart';
import 'package:app/features/matches/application/usecases/create_match_usecase.dart';
import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/matches/matches_providers.dart';

class RematchUseCase {
  final CreateMatchUseCase _createMatchUseCase;
  final GetMatchUseCase _getMatchUseCase;

  RematchUseCase(this._createMatchUseCase, this._getMatchUseCase);

  Future<MatchDetailsDto> execute({required String matchId}) async {
    final match = await _getMatchUseCase.execute(matchId: matchId);

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

    final createdMatch = await _createMatchUseCase.execute(
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

    return _getMatchUseCase.execute(matchId: createdMatch.matchId);
  }
}

final rematchUseCaseProvider = Provider<RematchUseCase>((ref) {
  return RematchUseCase(
    ref.read(createMatchUseCaseProvider),
    ref.read(getMatchUseCaseProvider),
  );
});
