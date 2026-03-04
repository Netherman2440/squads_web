import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';

abstract class TournamentRepository {
  Future<List<Tournament>> getTournaments({required String squadId});

  Future<Tournament> getTournament({required String tournamentId});

  Future<Tournament> createTournament({required String squadId, String? name});

  Future<Tournament> updateTournament({
    required String tournamentId,
    String? name,
    TournamentStatus? status,
    String? acceptedTournamentDraftId,
  });

  Future<void> deleteTournament({required String tournamentId});

  Future<List<TournamentTeam>> getTournamentTeams({
    required String tournamentId,
  });

  Future<List<String>> getTournamentPlayerIds({required String tournamentId});

  Future<void> replaceTournamentTeams({
    required String tournamentId,
    required List<TournamentTeamInput> teams,
  });

  Future<List<Match>> getTournamentMatches({required String tournamentId});
}
