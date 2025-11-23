import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/features/squads/application/apply_to_squad_use_case.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';

@GenerateMocks([SquadRepository])
import 'apply_to_squad_use_case_test.mocks.dart';

void main() {
  group('ApplyToSquadUseCase', () {
    late MockSquadRepository mockRepository;
    late ApplyToSquadUseCase useCase;

    setUp(() {
      mockRepository = MockSquadRepository();
      useCase = ApplyToSquadUseCase(mockRepository);
    });

    group('execute', () {
      const testSquadId = 'squad-123';
      const testUserId = 'user-456';

      test('calls repository applyToSquad with correct parameters', () async {
        when(mockRepository.applyToSquad(any, any))
            .thenAnswer((_) async => {});

        await useCase.execute(testSquadId, testUserId);

        verify(mockRepository.applyToSquad(testSquadId, testUserId)).called(1);
      });

      test('completes successfully when repository succeeds', () async {
        when(mockRepository.applyToSquad(any, any))
            .thenAnswer((_) async => {});

        await expectLater(
          useCase.execute(testSquadId, testUserId),
          completes,
        );
      });

      test('propagates repository exceptions', () async {
        when(mockRepository.applyToSquad(any, any))
            .thenThrow(Exception('Network error'));

        await expectLater(
          useCase.execute(testSquadId, testUserId),
          throwsException,
        );
      });

      test('handles empty squadId', () async {
        when(mockRepository.applyToSquad(any, any))
            .thenAnswer((_) async => {});

        await useCase.execute('', testUserId);

        verify(mockRepository.applyToSquad('', testUserId)).called(1);
      });

      test('handles empty userId', () async {
        when(mockRepository.applyToSquad(any, any))
            .thenAnswer((_) async => {});

        await useCase.execute(testSquadId, '');

        verify(mockRepository.applyToSquad(testSquadId, '')).called(1);
      });

      test('can be called multiple times', () async {
        when(mockRepository.applyToSquad(any, any))
            .thenAnswer((_) async => {});

        await useCase.execute('squad-1', 'user-1');
        await useCase.execute('squad-2', 'user-1');
        await useCase.execute('squad-3', 'user-2');

        verify(mockRepository.applyToSquad('squad-1', 'user-1')).called(1);
        verify(mockRepository.applyToSquad('squad-2', 'user-1')).called(1);
        verify(mockRepository.applyToSquad('squad-3', 'user-2')).called(1);
      });
    });
  });
}