import 'dart:math';

import 'package:app/core/error/failure.dart';
import 'package:app/core/utils/team_score.dart';
import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/players/domain/entities/player.dart';

class GreedyDraftRepository implements DraftRepository {
  const GreedyDraftRepository();

  @override
  Future<List<Draft>> createDraft({
    required List<Player> players,
    int limit = 20,
    bool playWithSubstitute = true,
  }) async {
    if (limit <= 0) {
      return [];
    }

    if (players.isEmpty) {
      return [];
    }

    // Greedy draft supports larger groups than the combinatory version, but we
    // still guard against absurd input sizes to keep the UI responsive.
    if (players.length > 200) {
      throw const ValidationFailure('Draft supports up to 200 players.');
    }

    final sortedById = [...players]
      ..sort(
        (a, b) => a.playerId.compareTo(b.playerId),
      );

    final n = sortedById.length;
    final isOdd = n.isOdd;
    final homeTargetSize = n ~/ 2;
    final awayTargetSize = n - homeTargetSize;

    final proposals = <_DraftProposal>[];
    final seen = <String>{};

    // We only need [limit] results, so we generate multiple greedy runs with
    // deterministic variation and deduplicate them.
    final maxAttempts = min(1000, max(limit * 60, limit));

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (proposals.length >= limit) {
        break;
      }

      final seed = _stableSeed(
        sortedPlayers: sortedById,
        attempt: attempt,
      );

      var draft = _buildGreedyDraft(
        sortedById: sortedById,
        seed: seed,
        homeTargetSize: homeTargetSize,
        awayTargetSize: awayTargetSize,
        playWithSubstitute: isOdd && playWithSubstitute,
      );

      draft = _improveBySwaps(
        draft: draft,
        homeTargetSize: homeTargetSize,
        awayTargetSize: awayTargetSize,
        playWithSubstitute: isOdd && playWithSubstitute,
        seed: seed,
      );

      draft = _canonicalizeDraft(
        sortedById: sortedById,
        draft: draft,
      );

      final signature = _draftSignature(draft);
      if (!seen.add(signature)) {
        continue;
      }

      final effectiveHome = effectiveTeamScore(
        totalScore: draft.homeTotalScore,
        teamSize: draft.homePlayers.length,
        opponentTeamSize: draft.awayPlayers.length,
        playWithSubstitute: isOdd && playWithSubstitute,
      );

      final effectiveAway = effectiveTeamScore(
        totalScore: draft.awayTotalScore,
        teamSize: draft.awayPlayers.length,
        opponentTeamSize: draft.homePlayers.length,
        playWithSubstitute: isOdd && playWithSubstitute,
      );

      proposals.add(
        _DraftProposal(
          draft: draft,
          teamDifference: (effectiveHome - effectiveAway).abs(),
          externalBalance: _calculateExternalBalance(
            draft.homePlayers,
            draft.awayPlayers,
          ),
        ),
      );
    }

    proposals.sort((a, b) {
      final byTeamDifference = a.teamDifference.compareTo(b.teamDifference);
      if (byTeamDifference != 0) {
        return byTeamDifference;
      }

      return a.externalBalance.compareTo(b.externalBalance);
    });

    return proposals.take(limit).map((p) => p.draft).toList(growable: false);
  }
}

class _DraftProposal {
  final Draft draft;
  final double teamDifference;
  final double externalBalance;

  const _DraftProposal({
    required this.draft,
    required this.teamDifference,
    required this.externalBalance,
  });
}

Draft _buildGreedyDraft({
  required List<Player> sortedById,
  required int seed,
  required int homeTargetSize,
  required int awayTargetSize,
  required bool playWithSubstitute,
}) {
  final rng = Random(seed);

  final byScore = [...sortedById]
    ..sort((a, b) {
      final byScoreDesc = b.score.compareTo(a.score);
      if (byScoreDesc != 0) {
        return byScoreDesc;
      }

      // Deterministic per-attempt tie-breaker.
      final ha = _stableHash32(a.playerId, seed);
      final hb = _stableHash32(b.playerId, seed);
      final byHash = ha.compareTo(hb);
      if (byHash != 0) {
        return byHash;
      }

      return a.playerId.compareTo(b.playerId);
    });

  // Shuffle within blocks to create different drafts while keeping strong
  // players early in the assignment order.
  final blockSize = 3 + (seed.abs() % 4); // 3..6
  for (var start = 0; start < byScore.length; start += blockSize) {
    final end = min(start + blockSize, byScore.length);
    for (var i = end - 1; i > start; i--) {
      final j = start + rng.nextInt(i - start + 1);
      final tmp = byScore[i];
      byScore[i] = byScore[j];
      byScore[j] = tmp;
    }
  }

  final home = <Player>[];
  final away = <Player>[];

  var homeTotal = 0.0;
  var awayTotal = 0.0;

  for (final player in byScore) {
    if (home.length >= homeTargetSize) {
      away.add(player);
      awayTotal += player.score;
      continue;
    }

    if (away.length >= awayTargetSize) {
      home.add(player);
      homeTotal += player.score;
      continue;
    }

    final diffIfHome = _effectiveDiffAfterAdd(
      addToHome: true,
      addScore: player.score,
      homeTotal: homeTotal,
      awayTotal: awayTotal,
      homeTargetSize: homeTargetSize,
      awayTargetSize: awayTargetSize,
      playWithSubstitute: playWithSubstitute,
    );

    final diffIfAway = _effectiveDiffAfterAdd(
      addToHome: false,
      addScore: player.score,
      homeTotal: homeTotal,
      awayTotal: awayTotal,
      homeTargetSize: homeTargetSize,
      awayTargetSize: awayTargetSize,
      playWithSubstitute: playWithSubstitute,
    );

    if (diffIfHome < diffIfAway) {
      home.add(player);
      homeTotal += player.score;
      continue;
    }

    if (diffIfAway < diffIfHome) {
      away.add(player);
      awayTotal += player.score;
      continue;
    }

    // Tie: pick deterministically based on seed/player id and current sizes to
    // produce diverse but stable results across attempts.
    final tieBreaker =
        _stableHash32(player.playerId, seed ^ home.length ^ away.length);
    final toHome = (tieBreaker & 1) == 0;

    if (toHome) {
      home.add(player);
      homeTotal += player.score;
    } else {
      away.add(player);
      awayTotal += player.score;
    }
  }

  home.sort((a, b) => a.playerId.compareTo(b.playerId));
  away.sort((a, b) => a.playerId.compareTo(b.playerId));

  return Draft(
    homePlayers: home,
    awayPlayers: away,
    homeTotalScore: homeTotal,
    awayTotalScore: awayTotal,
  );
}

double _effectiveDiffAfterAdd({
  required bool addToHome,
  required double addScore,
  required double homeTotal,
  required double awayTotal,
  required int homeTargetSize,
  required int awayTargetSize,
  required bool playWithSubstitute,
}) {
  final nextHomeTotal = addToHome ? homeTotal + addScore : homeTotal;
  final nextAwayTotal = addToHome ? awayTotal : awayTotal + addScore;

  final effectiveHome = effectiveTeamScore(
    totalScore: nextHomeTotal,
    teamSize: homeTargetSize,
    opponentTeamSize: awayTargetSize,
    playWithSubstitute: playWithSubstitute,
  );

  final effectiveAway = effectiveTeamScore(
    totalScore: nextAwayTotal,
    teamSize: awayTargetSize,
    opponentTeamSize: homeTargetSize,
    playWithSubstitute: playWithSubstitute,
  );

  return (effectiveHome - effectiveAway).abs();
}

Draft _improveBySwaps({
  required Draft draft,
  required int homeTargetSize,
  required int awayTargetSize,
  required bool playWithSubstitute,
  required int seed,
}) {
  if (draft.homePlayers.isEmpty || draft.awayPlayers.isEmpty) {
    return draft;
  }

  final isOdd = homeTargetSize != awayTargetSize;
  final rng = Random(seed ^ 0x9E3779B9);

  final home = [...draft.homePlayers];
  final away = [...draft.awayPlayers];

  var homeTotal = draft.homeTotalScore;
  var awayTotal = draft.awayTotalScore;

  double currentDiff() {
    final effectiveHome = effectiveTeamScore(
      totalScore: homeTotal,
      teamSize: homeTargetSize,
      opponentTeamSize: awayTargetSize,
      playWithSubstitute: playWithSubstitute,
    );

    final effectiveAway = effectiveTeamScore(
      totalScore: awayTotal,
      teamSize: awayTargetSize,
      opponentTeamSize: homeTargetSize,
      playWithSubstitute: playWithSubstitute,
    );

    return (effectiveHome - effectiveAway).abs();
  }

  var bestDiff = currentDiff();
  var bestExternal = _calculateExternalBalance(home, away);

  // Focus swaps around top players by score; this is a cheap local improvement.
  const maxIterations = 20;
  for (var iteration = 0; iteration < maxIterations; iteration++) {
    home.sort((a, b) => b.score.compareTo(a.score));
    away.sort((a, b) => b.score.compareTo(a.score));

    final probeHome = min(12, home.length);
    final probeAway = min(12, away.length);

    var improved = false;
    var bestHomeIdx = -1;
    var bestAwayIdx = -1;

    // Randomize probe order a bit for variety between attempts.
    final homeIndices = List<int>.generate(probeHome, (i) => i)
      ..shuffle(rng);
    final awayIndices = List<int>.generate(probeAway, (i) => i)
      ..shuffle(rng);

    for (final i in homeIndices) {
      final hp = home[i];
      for (final j in awayIndices) {
        final ap = away[j];

        final nextHomeTotal = homeTotal - hp.score + ap.score;
        final nextAwayTotal = awayTotal - ap.score + hp.score;

        final effectiveHome = effectiveTeamScore(
          totalScore: nextHomeTotal,
          teamSize: homeTargetSize,
          opponentTeamSize: awayTargetSize,
          playWithSubstitute: playWithSubstitute,
        );

        final effectiveAway = effectiveTeamScore(
          totalScore: nextAwayTotal,
          teamSize: awayTargetSize,
          opponentTeamSize: homeTargetSize,
          playWithSubstitute: playWithSubstitute,
        );

        final nextDiff = (effectiveHome - effectiveAway).abs();

        final diffEps = 1e-9;
        if (nextDiff > bestDiff + diffEps) {
          continue;
        }

        // Only compute external balance when it can affect ordering.
        final nextExternal = () {
          final nextHome = [...home]..[i] = ap;
          final nextAway = [...away]..[j] = hp;
          return _calculateExternalBalance(nextHome, nextAway);
        }();

        final isBetterDiff = nextDiff < bestDiff - diffEps;
        final isEqualDiff = (nextDiff - bestDiff).abs() <= diffEps;
        final isBetterExternal =
            isEqualDiff && nextExternal < bestExternal - diffEps;

        if (isBetterDiff || isBetterExternal) {
          improved = true;
          bestHomeIdx = i;
          bestAwayIdx = j;
          bestDiff = nextDiff;
          bestExternal = nextExternal;

          // In odd-sized games, the substitute adjustment already skews the
          // bigger team, so we accept the first strong improvement quickly.
          if (isOdd) {
            break;
          }
        }
      }
      if (improved && isOdd) {
        break;
      }
    }

    if (!improved) {
      break;
    }

    final hp = home[bestHomeIdx];
    final ap = away[bestAwayIdx];

    home[bestHomeIdx] = ap;
    away[bestAwayIdx] = hp;

    homeTotal = homeTotal - hp.score + ap.score;
    awayTotal = awayTotal - ap.score + hp.score;
  }

  home.sort((a, b) => a.playerId.compareTo(b.playerId));
  away.sort((a, b) => a.playerId.compareTo(b.playerId));

  return Draft(
    homePlayers: home,
    awayPlayers: away,
    homeTotalScore: homeTotal,
    awayTotalScore: awayTotal,
  );
}

Draft _canonicalizeDraft({
  required List<Player> sortedById,
  required Draft draft,
}) {
  final n = sortedById.length;
  if (n.isOdd) {
    // For odd n, home/away are not symmetric due to team sizes, so we keep as-is.
    return draft;
  }

  final smallestId = sortedById.first.playerId;
  final hasSmallestInHome =
      draft.homePlayers.any((p) => p.playerId == smallestId);

  if (hasSmallestInHome) {
    return draft;
  }

  return Draft(
    homePlayers: draft.awayPlayers,
    awayPlayers: draft.homePlayers,
    homeTotalScore: draft.awayTotalScore,
    awayTotalScore: draft.homeTotalScore,
  );
}

String _draftSignature(Draft draft) {
  final homeIds = draft.homePlayers.map((p) => p.playerId).join(',');
  final awayIds = draft.awayPlayers.map((p) => p.playerId).join(',');
  return '$homeIds|$awayIds';
}

int _stableSeed({
  required List<Player> sortedPlayers,
  required int attempt,
}) {
  var hash = 0x811C9DC5; // FNV-1a 32-bit offset basis
  hash = _fnv1a32Int(hash, attempt);
  for (final p in sortedPlayers) {
    hash = _fnv1a32String(hash, p.playerId);
    hash = _fnv1a32Int(hash, 0xFF);
  }
  return hash & 0x7FFFFFFF;
}

int _stableHash32(String input, int salt) {
  var hash = 0x811C9DC5;
  hash = _fnv1a32Int(hash, salt);
  hash = _fnv1a32String(hash, input);
  return hash;
}

int _fnv1a32String(int hash, String input) {
  var h = hash;
  for (final unit in input.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

int _fnv1a32Int(int hash, int input) {
  var h = hash;
  var v = input;
  // Mix 4 bytes little-endian.
  for (var i = 0; i < 4; i++) {
    h ^= (v & 0xFF);
    h = (h * 0x01000193) & 0xFFFFFFFF;
    v >>= 8;
  }
  return h;
}

/// Calculates external balance between two teams.
/// Compares corresponding player positions after sorting both teams.
/// Lower external balance = better distribution of top talent between teams.
double _calculateExternalBalance(List<Player> homePlayers, List<Player> awayPlayers) {
  if (homePlayers.isEmpty && awayPlayers.isEmpty) return 0.0;
  if (homePlayers.isEmpty || awayPlayers.isEmpty) return double.infinity;

  final homeScores = homePlayers.map((p) => p.score).toList()
    ..sort((a, b) => b.compareTo(a));
  final awayScores = awayPlayers.map((p) => p.score).toList()
    ..sort((a, b) => b.compareTo(a));

  var totalDifference = 0.0;
  final minLength =
      homeScores.length < awayScores.length ? homeScores.length : awayScores.length;

  for (var i = 0; i < minLength; i++) {
    totalDifference += (homeScores[i] - awayScores[i]).abs();
  }

  return totalDifference;
}