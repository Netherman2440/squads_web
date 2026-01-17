import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/application/get_squad_stats_use_case.dart';
import 'package:app/features/squads/domain/entities/squad_stats.dart';
import 'package:app/features/squads/presentation/state/squad_stats_provider.dart';

class _MockGetSquadStatsUseCase extends Mock implements GetSquadStatsUseCase {}

void main() {
  late ProviderContainer container;
  late _MockGetSquadStatsUseCase useCase;

  final player = Player(
    playerId: 'player-1',
    squadId: 'squad-123',
    name: 'Ada Lovelace',
    position: 'FWD',
    baseRanking: 50,
    ranking: 72.5,
    createdAt: DateTime.now(), //const
  );

  final stats = SquadStats(
    topPlayer: player,
    worstPlayer: player,
    topRisingStar: player,
    matchesCount: 12,
    totalGoals: 30,
    totalHomeGoals: 18,
    totalAwayGoals: 12,
    avgGoalsPerMatch: 2.5,
    avgHomeGoals: 1.5,
    avgAwayGoals: 1.0,
    playersCount: 8,
    avgPlayerScore: 60.25,
  );

  setUp(() {
    useCase = _MockGetSquadStatsUseCase();
    container = ProviderContainer(
      overrides: [getSquadStatsUseCaseProvider.overrideWithValue(useCase)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('provides squad stats from use case', () async {
    when(
      () => useCase.execute(squadId: 'squad-123'),
    ).thenAnswer((_) async => stats);

    final result = await container.read(squadStatsProvider('squad-123').future);

    expect(result, same(stats));
    verify(() => useCase.execute(squadId: 'squad-123')).called(1);
  });
}
