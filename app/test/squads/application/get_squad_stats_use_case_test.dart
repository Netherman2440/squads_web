import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/application/get_squad_stats_use_case.dart';
import 'package:app/features/squads/domain/entities/squad_stats.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';

class _MockSquadRepository extends Mock implements SquadRepository {}

void main() {
  late _MockSquadRepository squadRepository;
  late GetSquadStatsUseCase useCase;

  final player = Player(
    playerId: 'player-1',
    squadId: 'squad-123',
    name: 'Ada Lovelace',
    position: 'FWD',
    baseRanking: 50,
    ranking: 72.5,
    createdAt: DateTime(2024, 1, 1),
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
    squadRepository = _MockSquadRepository();
    useCase = GetSquadStatsUseCase(squadRepository);
  });

  test('returns squad stats from repository', () async {
    when(
      () => squadRepository.getSquadStats('squad-123'),
    ).thenAnswer((_) async => stats);

    final result = await useCase.execute(squadId: 'squad-123');

    expect(result, same(stats));
    verify(() => squadRepository.getSquadStats('squad-123')).called(1);
  });

  test('rethrows repository error', () async {
    when(
      () => squadRepository.getSquadStats('squad-123'),
    ).thenThrow(Exception('boom'));

    await expectLater(useCase.execute(squadId: 'squad-123'), throwsException);
  });
}
