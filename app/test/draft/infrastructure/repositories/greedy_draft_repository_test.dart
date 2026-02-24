import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/infrastructure/repositories/greedy_draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

void main() {
  const repository = GreedyDraftRepository(candidatePoolSize: 22);

  test('creates deterministic proposals for same seed', () async {
    final players = _players(10, ranking: 100);

    final first = await repository.createDraft(
      players: players,
      teamCount: 3,
      seed: 42,
      limit: 5,
    );
    final second = await repository.createDraft(
      players: players,
      teamCount: 3,
      seed: 42,
      limit: 5,
    );

    expect(first, isNotEmpty);
    expect(second, isNotEmpty);
    expect(_draftKey(first.first), _draftKey(second.first));
    expect(first.first.teams.length, 3);

    final teamSizes =
        first.first.teams.map((team) => team.players.length).toList()..sort();
    expect(teamSizes, [3, 3, 4]);
  });

  test('position penalty prefers splitting duplicated positions', () async {
    final players = [
      _player(id: 'gk1', ranking: 10, position: 'gk'),
      _player(id: 'gk2', ranking: 10, position: 'gk'),
      _player(id: 'fwd1', ranking: 10, position: 'fwd'),
      _player(id: 'fwd2', ranking: 10, position: 'fwd'),
    ];

    final proposals = await repository.createDraft(
      players: players,
      teamCount: 2,
      seed: 1,
      limit: 1,
    );

    expect(proposals, isNotEmpty);
    expect(_sameTeam(proposals.first, 'gk1', 'gk2'), isFalse);
  });

  test('supports together rules for multiple teams', () async {
    final players = _players(9, ranking: 100);

    final proposals = await repository.createDraft(
      players: players,
      teamCount: 3,
      seed: 123,
      rules: const [
        DraftRule(type: DraftRuleType.together, playerIds: ['p1', 'p2', 'p3']),
      ],
      limit: 1,
    );

    expect(proposals, isNotEmpty);
    expect(_sameTeam(proposals.first, 'p1', 'p2'), isTrue);
    expect(_sameTeam(proposals.first, 'p2', 'p3'), isTrue);
  });

  test('supports against rules for multiple teams', () async {
    final players = _players(9, ranking: 100);

    final proposals = await repository.createDraft(
      players: players,
      teamCount: 3,
      seed: 77,
      rules: const [
        DraftRule(type: DraftRuleType.against, playerIds: ['p1', 'p2', 'p3']),
      ],
      limit: 1,
    );

    expect(proposals, isNotEmpty);
    expect(_sameTeam(proposals.first, 'p1', 'p2'), isFalse);
    expect(_sameTeam(proposals.first, 'p1', 'p3'), isFalse);
    expect(_sameTeam(proposals.first, 'p2', 'p3'), isFalse);
  });
}

List<Player> _players(int count, {double ranking = 50}) {
  return List<Player>.generate(
    count,
    (index) => _player(
      id: 'p${index + 1}',
      ranking: ranking,
      position: index.isEven ? 'gk' : 'fwd',
    ),
  );
}

Player _player({
  required String id,
  required double ranking,
  String? position,
}) {
  return Player(
    playerId: id,
    squadId: 'squad-1',
    name: id,
    position: position,
    baseRanking: ranking.toInt(),
    ranking: ranking,
    createdAt: DateTime(2025, 1, 1),
  );
}

String _draftKey(Draft draft) {
  final teams =
      draft.teams
          .map((team) => team.players.map((p) => p.playerId).toList()..sort())
          .map((ids) => ids.join(','))
          .toList()
        ..sort();
  return teams.join('|');
}

bool _sameTeam(Draft draft, String playerA, String playerB) {
  for (final team in draft.teams) {
    final ids = team.players.map((p) => p.playerId).toSet();
    if (ids.contains(playerA) && ids.contains(playerB)) {
      return true;
    }
  }
  return false;
}
