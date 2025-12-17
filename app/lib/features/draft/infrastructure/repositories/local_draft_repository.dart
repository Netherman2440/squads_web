import 'dart:math' as math;

import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

class LocalDraftRepository implements DraftRepository {
  const LocalDraftRepository();

  @override
  Future<List<Draft>> createDraft({
    required List<Player> players,
    int limit = 20,
  }) async {
    if (players.length > 16) {
      throw const ValidationFailure('Draft supports up to 16 players.');
    }

    if (players.isEmpty) {
      return [];
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

      var homeMin = double.infinity;
      var awayMin = double.infinity;

      for (var i = 0; i < n; i++) {
        final player = sorted[i];
        final score = indexedScores[i];
        final isHome = (mask & (1 << i)) != 0;

        if (isHome) {
          homePlayers.add(player);
          homeTotal += score;
          homeMin = math.min(homeMin, score);
        } else {
          awayPlayers.add(player);
          awayTotal += score;
          awayMin = math.min(awayMin, score);
        }
      }

      final effectiveHome = isOdd ? homeTotal - homeMin : homeTotal;
      final effectiveAway = isOdd ? awayTotal - awayMin : awayTotal;

      proposals.add(
        _DraftProposal(
          draft: Draft(
            homePlayers: homePlayers,
            awayPlayers: awayPlayers,
            homeTotalScore: homeTotal,
            awayTotalScore: awayTotal,
          ),
          balance: (effectiveHome - effectiveAway).abs(),
          tieBreaker: homePlayers
              .map((p) => p.playerId)
              .toList(growable: false)
            ..sort(),
        ),
      );
    }

    proposals.sort((a, b) {
      final byBalance = a.balance.compareTo(b.balance);
      if (byBalance != 0) {
        return byBalance;
      }

      final aKey = a.tieBreaker.join(',');
      final bKey = b.tieBreaker.join(',');
      return aKey.compareTo(bKey);
    });

    return proposals.take(limit).map((p) => p.draft).toList(growable: false);
  }
}

class _DraftProposal {
  final Draft draft;
  final double balance;
  final List<String> tieBreaker;

  const _DraftProposal({
    required this.draft,
    required this.balance,
    required this.tieBreaker,
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
