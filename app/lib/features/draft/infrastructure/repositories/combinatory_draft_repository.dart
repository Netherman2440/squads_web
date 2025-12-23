import 'package:app/core/error/failure.dart';
import 'package:app/core/utils/team_score.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

class CombinatoryDraftRepository implements DraftRepository {
  const CombinatoryDraftRepository();

  @override
  Future<List<Draft>> createDraft({
    required List<Player> players,
    int limit = 20,
    bool playWithSubstitute = true,
  }) async {
    if (players.isEmpty) {
      return [];
    }

    if (players.length < 2) {
      throw const ValidationFailure(
        'Draft requires at least 2 players.',
      );
    }

    if (players.length > 16) {
      throw const ValidationFailure('Draft supports up to 16 players.');
    }

    final sorted = [...players]
      ..sort(
        (a, b) => a.playerId.compareTo(b.playerId),
      );

    final n = sorted.length;
    final isOdd = n.isOdd;
    final k = n ~/ 2;

    final indexedScores = sorted.map((p) => p.score).toList(growable: false);

    final proposals = <_DraftProposal>[];

    final totalMasks = 1 << n;

    for (var mask = 0; mask < totalMasks; mask++) {
      if (_popcount(mask) != k) {
        continue;
      }

      if (!isOdd) {
        final hasSmallestInHome = (mask & 1) == 1;
        if (!hasSmallestInHome) {
          continue;
        }
      }

      final homePlayers = <Player>[];
      final awayPlayers = <Player>[];

      var homeTotal = 0.0;
      var awayTotal = 0.0;

      for (var i = 0; i < n; i++) {
        final player = sorted[i];
        final score = indexedScores[i];
        final isHome = (mask & (1 << i)) != 0;

        if (isHome) {
          homePlayers.add(player);
          homeTotal += score;
        } else {
          awayPlayers.add(player);
          awayTotal += score;
        }
      }

      final effectiveHome = effectiveTeamScore(
        totalScore: homeTotal,
        teamSize: homePlayers.length,
        opponentTeamSize: awayPlayers.length,
        playWithSubstitute: isOdd && playWithSubstitute,
      );

      final effectiveAway = effectiveTeamScore(
        totalScore: awayTotal,
        teamSize: awayPlayers.length,
        opponentTeamSize: homePlayers.length,
        playWithSubstitute: isOdd && playWithSubstitute,
      );

      // Calculate external balance - how well top players are distributed between teams
      final externalBalance = _calculateExternalBalance(homePlayers, awayPlayers);

      proposals.add(
        _DraftProposal(
          draft: Draft(
            homePlayers: homePlayers,
            awayPlayers: awayPlayers,
            homeTotalScore: homeTotal,
            awayTotalScore: awayTotal,
          ),
          teamDifference: (effectiveHome - effectiveAway).abs(),
          externalBalance: externalBalance,
        ),
      );
    }

    proposals.sort((a, b) {
      final byTeamDifference = a.teamDifference.compareTo(b.teamDifference);
      if (byTeamDifference != 0) {
        return byTeamDifference;
      }

      // When team differences are equal, prefer teams where top players are better distributed
      // (smaller external balance = better distribution of talent between teams)
      return a.externalBalance.compareTo(b.externalBalance);
    });

    return proposals.take(limit).map((p) => p.draft).toList(growable: false);
  }
}

class _DraftProposal {
  final Draft draft;
  final double teamDifference; // absolute difference between team scores
  final double externalBalance; // sum of differences between corresponding player positions

  const _DraftProposal({
    required this.draft,
    required this.teamDifference,
    required this.externalBalance,
  });
}

int _popcount(int value) {
  var v = value;
  var count = 0;
  while (v != 0) {
    v &= v - 1;
    count++;
  }
  return count;
}

/// Calculates external balance between two teams.
/// Compares corresponding player positions after sorting both teams.
/// Lower external balance = better distribution of top talent between teams.
double _calculateExternalBalance(List<Player> homePlayers, List<Player> awayPlayers) {
  if (homePlayers.isEmpty && awayPlayers.isEmpty) return 0.0;
  if (homePlayers.isEmpty || awayPlayers.isEmpty) return double.infinity;

  // Sort both teams by score (best players first)
  final homeScores = homePlayers.map((p) => p.score).toList()..sort((a, b) => b.compareTo(a));
  final awayScores = awayPlayers.map((p) => p.score).toList()..sort((a, b) => b.compareTo(a));

  // Compare corresponding positions
  var totalDifference = 0.0;
  final minLength = homeScores.length < awayScores.length ? homeScores.length : awayScores.length;

  for (var i = 0; i < minLength; i++) {
    totalDifference += (homeScores[i] - awayScores[i]).abs();
  }

  return totalDifference;
}
