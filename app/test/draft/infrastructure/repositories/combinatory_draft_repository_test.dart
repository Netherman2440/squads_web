import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/infrastructure/repositories/combinatory_draft_repository.dart';
import 'package:app/features/players/domain/entities/player.dart';

void main() {
  const repository = CombinatoryDraftRepository();

  test('creates deterministic proposals for multiple teams', () async {
    final players = _players(6);

    final first = await repository.createDraft(players: players, teamCount: 3);
    final second = await repository.createDraft(players: players, teamCount: 3);

    expect(first, isNotEmpty);
    expect(second, isNotEmpty);
    expect(_draftKey(first.first), _draftKey(second.first));

    final proposal = first.first;
    expect(proposal.teams.length, 3);
    expect(_allPlayerIds(proposal).length, 6);
  });

  test('prefers satisfying together rule via soft penalty', () async {
    final players = _players(4, ranking: 100);

    final proposals = await repository.createDraft(
      players: players,
      teamCount: 2,
      rules: const [
        DraftRule(type: DraftRuleType.together, playerIds: ['p1', 'p2']),
      ],
    );

    expect(proposals, isNotEmpty);
    expect(_sameTeam(proposals.first, 'p1', 'p2'), isTrue);
  });

  test('prefers satisfying against rule via soft penalty', () async {
    final players = _players(4, ranking: 100);

    final proposals = await repository.createDraft(
      players: players,
      teamCount: 2,
      rules: const [
        DraftRule(type: DraftRuleType.against, playerIds: ['p1', 'p2']),
      ],
    );

    expect(proposals, isNotEmpty);
    expect(_sameTeam(proposals.first, 'p1', 'p2'), isFalse);
  });
}

List<Player> _players(int count, {double ranking = 50}) {
  return List<Player>.generate(
    count,
    (index) => Player(
      playerId: 'p${index + 1}',
      squadId: 'squad-1',
      name: 'Player ${index + 1}',
      position: index.isEven ? 'gk' : 'fwd',
      baseRanking: ranking.toInt(),
      ranking: ranking,
      createdAt: DateTime(2025, 1, 1),
    ),
  );
}

String _draftKey(Draft draft) {
  final teams = draft.teams
      .map((team) => team.players.map((p) => p.playerId).toList()..sort())
      .map((ids) => ids.join(','))
      .toList();
  return teams.join('|');
}

Set<String> _allPlayerIds(Draft draft) {
  return draft.teams
      .expand((team) => team.players)
      .map((player) => player.playerId)
      .toSet();
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
