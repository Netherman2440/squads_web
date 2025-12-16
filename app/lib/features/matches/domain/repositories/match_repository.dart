import 'package:app/features/matches/domain/entities/match.dart';

abstract class MatchRepository {
  Future<List<Match>> getSquadMatches({required String squadId});
  Future<Match> getMatch({required String matchId});
}
