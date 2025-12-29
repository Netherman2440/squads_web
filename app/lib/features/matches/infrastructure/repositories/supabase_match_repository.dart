import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/global_dependencies.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/core/error/supabase_error_extension.dart';

import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/entities/team.dart';
import 'package:app/features/matches/domain/entities/match_enums.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';

class SupabaseMatchRepository implements MatchRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseMatchRepository');

  SupabaseMatchRepository(this._supabase);

  @override
  Future<List<Match>> getSquadMatches({required String squadId}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select()
          .eq('squad_id', squadId)
          .order('played_at', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((row) => Match.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to fetch matches for squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<Match> getMatch({required String matchId}) async {
    try {
      // 1. Fetch Match
      final matchResponse = await _supabase
          .from('matches')
          .select()
          .eq('match_id', matchId)
          .maybeSingle();

      if (matchResponse == null) {
        throw const NotFoundFailure('Match not found');
      }

      final matchData = Map<String, dynamic>.from(matchResponse as Map);
      var match = Match.fromJson(matchData);

      // 2. Fetch Teams
      final teamsResponse = await _supabase
          .from('teams')
          .select()
          .eq('match_id', matchId);

      final List<dynamic> teamsData = teamsResponse as List<dynamic>;
      List<Team> teams = teamsData
          .map((row) => Team.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();

      // 3. For each team, fetch players
      List<Team> teamsWithPlayers = [];
      for (var team in teams) {
        // Fetch team_players
        final teamPlayersResponse = await _supabase
            .from('team_players')
            .select('player_id')
            .eq('match_id', matchId)
            .eq('team_id', team.teamId);

        final List<dynamic> teamPlayersData =
            teamPlayersResponse as List<dynamic>;
        if (teamPlayersData.isEmpty) {
          teamsWithPlayers.add(team);
          continue;
        }

        final playerIds = teamPlayersData
            .map((tp) => tp['player_id'] as String)
            .toList();

        // Fetch players details
        final playersResponse = await _supabase
            .from('players')
            .select()
            .inFilter('player_id', playerIds);

        final List<dynamic> playersData = playersResponse as List<dynamic>;
        final players = playersData
            .map((row) => Player.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();

        teamsWithPlayers.add(team.copyWith(players: players));
      }

      // Assign teams to match
      final homeTeam = teamsWithPlayers.firstWhere(
        (t) => t.side == Side.home,
        orElse: () => throw const ServerFailure('Home team missing'),
      );
      final awayTeam = teamsWithPlayers.firstWhere(
        (t) => t.side == Side.away,
        orElse: () => throw const ServerFailure('Away team missing'),
      );

      return match.copyWith(homeTeam: homeTeam, awayTeam: awayTeam);
    } catch (e, stack) {
      _logger.severe('Failed to fetch match $matchId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<Match> createMatch({
    required String squadId,
    String? tournamentId,
    required Team homeTeam,
    required Team awayTeam,
  }) async {
    try {
      final matchId = const Uuid().v4();
      final homeTeamId = const Uuid().v4();
      final awayTeamId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      // We should use a transaction or batch these if possible,
      // but Supabase/PostgREST doesn't support transactions over HTTP easily without RPC.
      // We will do sequential inserts for now, as is common in this stack.
      // Or we can use rpc if we wrote one, but we are keeping logic in app as per previous patterns (unless strictly required).
      // Ideally this should be a single RPC call for atomicity.
      // For now, I'll do sequential writes.

      // 1. Insert Match
      final matchData = {
        'match_id': matchId,
        'squad_id': squadId,
        'tournament_id': tournamentId,
        'created_at': now.toIso8601String(),
        'score_meta': {},
      };

      await _supabase.from('matches').insert(matchData);

      // 2. Insert Teams
      final homeTeamData = {
        'team_id': homeTeamId,
        'match_id': matchId,
        'side': 'home', // or Side.home.name if stringified correctly
        'name': homeTeam.name,
        'color': homeTeam.color,
        'created_at': now.toIso8601String(),
      };
      final awayTeamData = {
        'team_id': awayTeamId,
        'match_id': matchId,
        'side': 'away',
        'name': awayTeam.name,
        'color': awayTeam.color,
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('teams').insert([homeTeamData, awayTeamData]);

      // 3. Insert Team Players
      final List<Map<String, dynamic>> teamPlayersRows = [];

      for (final player in homeTeam.players) {
        teamPlayersRows.add({
          'match_id': matchId,
          'team_id': homeTeamId,
          'player_id': player.playerId,
          'tournament_id': tournamentId,
          'created_at': now.toIso8601String(),
        });
      }
      for (final player in awayTeam.players) {
        teamPlayersRows.add({
          'match_id': matchId,
          'team_id': awayTeamId,
          'player_id': player.playerId,
          'tournament_id': tournamentId,
          'created_at': now.toIso8601String(),
        });
      }

      if (teamPlayersRows.isNotEmpty) {
        await _supabase.from('team_players').insert(teamPlayersRows);
      }

      // Return the full match object
      return Match(
        matchId: matchId,
        squadId: squadId,
        tournamentId: tournamentId,
        createdAt: now,
        homeTeam: homeTeam.copyWith(
          teamId: homeTeamId,
          matchId: matchId,
          side: Side.home,
        ),
        awayTeam: awayTeam.copyWith(
          teamId: awayTeamId,
          matchId: matchId,
          side: Side.away,
        ),
      );
    } catch (e, stack) {
      _logger.severe('Failed to create match for squad $squadId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<void> deleteMatch({required String matchId}) async {
    try {
      await _supabase.from('matches').delete().eq('match_id', matchId);
    } catch (e, stack) {
      _logger.severe('Failed to delete match $matchId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<Match> updateMatchScore({
    required String matchId,
    MatchScoreType? scoreType,
    int? homeScore,
    int? awayScore,
    Map<String, dynamic>? scoreMeta,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (scoreType != null)
        updates['score_type'] =
            scoreType.name; // assuming name matches enum string
      // Allow setting null scores if needed? Or just updates?
      // The requirement implies setting the score.
      if (homeScore != null) updates['home_score'] = homeScore;
      if (awayScore != null) updates['away_score'] = awayScore;
      if (scoreMeta != null) updates['score_meta'] = scoreMeta;

      if (updates.isEmpty) return getMatch(matchId: matchId);

      await _supabase.from('matches').update(updates).eq('match_id', matchId);

      return getMatch(matchId: matchId);
    } catch (e, stack) {
      _logger.severe('Failed to update score for match $matchId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<Match> updateMatchTeams({
    required String matchId,
    required List<String> homePlayerIds,
    required List<String> awayPlayerIds,
  }) async {
    // This is tricky without transaction.
    // 1. Get current teams
    // 2. Delete existing team_players for this match
    // 3. Insert new team_players
    try {
      // Get team IDs first
      final teamsResponse = await _supabase
          .from('teams')
          .select('team_id, side')
          .eq('match_id', matchId);

      final teamsData = teamsResponse as List<dynamic>;
      final homeTeamId =
          teamsData.firstWhere((t) => t['side'] == 'home')['team_id'] as String;
      final awayTeamId =
          teamsData.firstWhere((t) => t['side'] == 'away')['team_id'] as String;

      // Delete all players for this match
      await _supabase.from('team_players').delete().eq('match_id', matchId);

      // Insert new
      final List<Map<String, dynamic>> teamPlayersRows = [];
      final now = DateTime.now()
          .toUtc(); // Use now or preserve original? New entry means new association.

      for (final pid in homePlayerIds) {
        teamPlayersRows.add({
          'match_id': matchId,
          'team_id': homeTeamId,
          'player_id': pid,
          'created_at': now.toIso8601String(),
        });
      }
      for (final pid in awayPlayerIds) {
        teamPlayersRows.add({
          'match_id': matchId,
          'team_id': awayTeamId,
          'player_id': pid,
          'created_at': now.toIso8601String(),
        });
      }

      if (teamPlayersRows.isNotEmpty) {
        await _supabase.from('team_players').insert(teamPlayersRows);
      }

      return getMatch(matchId: matchId);
    } catch (e, stack) {
      _logger.severe('Failed to update teams for match $matchId', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<Team> updateTeam({
    required String matchId,
    required String teamId,
    String? name,
    String? color,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (color != null) updates['color'] = color;

      if (updates.isEmpty) {
        // Return current team state (partial fetch)
        // Ideally we should fetch the specific team completely.
        // For now, let's reuse getMatch or fetch specific team logic
        throw UnimplementedError(
          'Fetch specific team not implemented, just return from update',
        );
      }

      final response = await _supabase
          .from('teams')
          .update(updates)
          .eq('team_id', teamId)
          .eq('match_id', matchId)
          .select()
          .single();

      // We need to return Team with players.
      // Simpler to just re-fetch the whole match or implement specific fetch.
      // Let's implement partial fetch for Team with Players.

      final teamData = Map<String, dynamic>.from(response as Map);
      var team = Team.fromJson(teamData);

      // Fetch players for this team
      final teamPlayersResponse = await _supabase
          .from('team_players')
          .select('player_id')
          .eq('match_id', matchId)
          .eq('team_id', teamId);

      final playerIds = (teamPlayersResponse as List<dynamic>)
          .map((tp) => tp['player_id'] as String)
          .toList();

      if (playerIds.isNotEmpty) {
        final playersResponse = await _supabase
            .from('players')
            .select()
            .inFilter('player_id', playerIds);

        final players = (playersResponse as List<dynamic>)
            .map((row) => Player.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();

        team = team.copyWith(players: players);
      }

      return team;
    } catch (e, stack) {
      _logger.severe(
        'Failed to update team $teamId in match $matchId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseMatchRepository(supabase);
});
