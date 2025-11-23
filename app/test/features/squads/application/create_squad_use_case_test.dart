import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/features/squads/application/create_squad_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';

@GenerateMocks([SquadRepository])
import 'create_squad_use_case_test.mocks.dart';

void main() {
  group('CreateSquadResult', () {
    test('success constructor creates successful result', () {
      const result = CreateSquadResult.success();

      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('failure constructor creates failed result with error', () {
      const result = CreateSquadResult.failure('Test error');

      expect(result.success, isFalse);
      expect(result.error, equals('Test error'));
    });
  });

  group('CreateSquadUseCase', () {
    late MockSquadRepository mockRepository;
    late CreateSquadUseCase useCase;

    setUp(() {
      mockRepository = MockSquadRepository();
      useCase = CreateSquadUseCase(mockRepository);
    });

    group('execute', () {
      const testName = 'Test Squad';
      const testVisibility = SquadVisibility.public;
      const testOwnerId = 'owner-123';
      const testSportType = SportType.football;

      test('returns failure when name is empty', () async {
        final result = await useCase.execute(
          name: '',
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isFalse);
        expect(result.error, equals('Squad name cannot be empty'));
        verifyNever(mockRepository.getUserSquads(any));
        verifyNever(mockRepository.createSquad(any, any, any, any));
      });

      test('returns failure when name is only whitespace', () async {
        final result = await useCase.execute(
          name: '   ',
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isFalse);
        expect(result.error, equals('Squad name cannot be empty'));
      });

      test('returns failure when user already owns a squad', () async {
        final existingSquad = Squad(
          id: 'existing-squad',
          ownerId: testOwnerId,
          name: 'Existing Squad',
          visibility: SquadVisibility.public,
          sportType: SportType.football,
          createdAt: DateTime.now(),
          memberCount: 1,
          role: SquadRole.owner,
        );

        when(mockRepository.getUserSquads(testOwnerId))
            .thenAnswer((_) async => [existingSquad]);

        final result = await useCase.execute(
          name: testName,
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isFalse);
        expect(
          result.error,
          equals('You can own only one squad. Please manage your existing squad.'),
        );
        verify(mockRepository.getUserSquads(testOwnerId)).called(1);
        verifyNever(mockRepository.createSquad(any, any, any, any));
      });

      test('allows user to create squad if they are member of other squads', () async {
        final memberSquad = Squad(
          id: 'other-squad',
          ownerId: 'other-owner',
          name: 'Other Squad',
          visibility: SquadVisibility.public,
          sportType: SportType.football,
          createdAt: DateTime.now(),
          memberCount: 5,
          role: SquadRole.member,
        );

        when(mockRepository.getUserSquads(testOwnerId))
            .thenAnswer((_) async => [memberSquad]);
        when(mockRepository.createSquad(any, any, any, any))
            .thenAnswer((_) async => {});

        final result = await useCase.execute(
          name: testName,
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isTrue);
        verify(mockRepository.createSquad(
          testName,
          testVisibility,
          testOwnerId,
          testSportType.name,
        )).called(1);
      });

      test('successfully creates squad when user has no existing squads', () async {
        when(mockRepository.getUserSquads(testOwnerId))
            .thenAnswer((_) async => []);
        when(mockRepository.createSquad(any, any, any, any))
            .thenAnswer((_) async => {});

        final result = await useCase.execute(
          name: testName,
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isTrue);
        expect(result.error, isNull);
        verify(mockRepository.getUserSquads(testOwnerId)).called(1);
        verify(mockRepository.createSquad(
          testName,
          testVisibility,
          testOwnerId,
          testSportType.name,
        )).called(1);
      });

      test('trims squad name before creating', () async {
        when(mockRepository.getUserSquads(testOwnerId))
            .thenAnswer((_) async => []);
        when(mockRepository.createSquad(any, any, any, any))
            .thenAnswer((_) async => {});

        final result = await useCase.execute(
          name: '  Test Squad  ',
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isTrue);
        verify(mockRepository.createSquad(
          'Test Squad',
          testVisibility,
          testOwnerId,
          testSportType.name,
        )).called(1);
      });

      test('handles private visibility correctly', () async {
        when(mockRepository.getUserSquads(testOwnerId))
            .thenAnswer((_) async => []);
        when(mockRepository.createSquad(any, any, any, any))
            .thenAnswer((_) async => {});

        final result = await useCase.execute(
          name: testName,
          visibility: SquadVisibility.private,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isTrue);
        verify(mockRepository.createSquad(
          testName,
          SquadVisibility.private,
          testOwnerId,
          testSportType.name,
        )).called(1);
      });

      test('propagates repository exceptions', () async {
        when(mockRepository.getUserSquads(testOwnerId))
            .thenThrow(Exception('Database error'));

        expect(
          () => useCase.execute(
            name: testName,
            visibility: testVisibility,
            ownerId: testOwnerId,
            sportType: testSportType,
          ),
          throwsException,
        );
      });

      test('checks ownership correctly when user owns squad with different ownerId', () async {
        // Edge case: user is owner but ownerId doesn't match (shouldn't happen, but testing the logic)
        final squadWithDifferentOwner = Squad(
          id: 'squad-1',
          ownerId: 'different-owner',
          name: 'Squad',
          visibility: SquadVisibility.public,
          sportType: SportType.football,
          createdAt: DateTime.now(),
          memberCount: 1,
          role: SquadRole.owner,
        );

        when(mockRepository.getUserSquads(testOwnerId))
            .thenAnswer((_) async => [squadWithDifferentOwner]);
        when(mockRepository.createSquad(any, any, any, any))
            .thenAnswer((_) async => {});

        // Should allow creation because ownerId doesn't match current user
        final result = await useCase.execute(
          name: testName,
          visibility: testVisibility,
          ownerId: testOwnerId,
          sportType: testSportType,
        );

        expect(result.success, isTrue);
      });
    });
  });
}