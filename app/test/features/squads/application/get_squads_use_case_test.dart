import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/features/squads/application/get_squads_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';

@GenerateMocks([SquadRepository])
import 'get_squads_use_case_test.mocks.dart';

void main() {
  group('GetSquadsUseCase', () {
    late MockSquadRepository mockRepository;
    late GetSquadsUseCase useCase;
    late List<Squad> testSquads;
    late DateTime testDate;

    setUp(() {
      mockRepository = MockSquadRepository();
      useCase = GetSquadsUseCase(mockRepository);
      testDate = DateTime(2024, 1, 1);

      testSquads = [
        Squad(
          id: 'squad-1',
          ownerId: 'owner-1',
          name: 'Squad 1',
          visibility: SquadVisibility.public,
          sportType: SportType.football,
          createdAt: testDate,
          memberCount: 5,
          role: SquadRole.none,
        ),
        Squad(
          id: 'squad-2',
          ownerId: 'owner-2',
          name: 'Squad 2',
          visibility: SquadVisibility.private,
          sportType: SportType.football,
          createdAt: testDate,
          memberCount: 3,
          role: SquadRole.none,
        ),
      ];
    });

    group('execute', () {
      test('returns squads without role enrichment for guest users', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);

        final result = await useCase.execute(isGuest: true);

        expect(result, equals(testSquads));
        verify(mockRepository.getSquads()).called(1);
        verifyNever(mockRepository.getUserSquads(any));
      });

      test('returns squads without role enrichment when userId is null', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);

        final result = await useCase.execute(userId: null, isGuest: false);

        expect(result, equals(testSquads));
        verifyNever(mockRepository.getUserSquads(any));
      });

      test('enriches squads with user roles for logged-in users', () async {
        const userId = 'user-123';
        final userSquadWithRole = Squad(
          id: 'squad-1',
          ownerId: 'owner-1',
          name: 'Squad 1',
          visibility: SquadVisibility.public,
          sportType: SportType.football,
          createdAt: testDate,
          memberCount: 5,
          role: SquadRole.member,
        );

        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);
        when(mockRepository.getUserSquads(userId))
            .thenAnswer((_) async => [userSquadWithRole]);

        final result = await useCase.execute(userId: userId, isGuest: false);

        expect(result.length, equals(2));
        expect(result[0].id, equals('squad-1'));
        expect(result[0].role, equals(SquadRole.member));
        expect(result[1].id, equals('squad-2'));
        expect(result[1].role, equals(SquadRole.none)); // Not in user's squads
      });

      test('forwards visibility filter to repository', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);

        await useCase.execute(
          visibility: SquadVisibility.private,
          isGuest: true,
        );

        verify(mockRepository.getSquads(
          visibility: SquadVisibility.private,
        )).called(1);
      });

      test('forwards search query to repository', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);

        await useCase.execute(
          searchQuery: 'test search',
          isGuest: true,
        );

        verify(mockRepository.getSquads(
          searchQuery: 'test search',
        )).called(1);
      });

      test('forwards sport type to repository', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);

        await useCase.execute(
          sportType: 'football',
          isGuest: true,
        );

        verify(mockRepository.getSquads(
          sportType: 'football',
        )).called(1);
      });

      test('forwards all filters together', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);

        await useCase.execute(
          visibility: SquadVisibility.public,
          searchQuery: 'champions',
          sportType: 'football',
          isGuest: true,
        );

        verify(mockRepository.getSquads(
          visibility: SquadVisibility.public,
          searchQuery: 'champions',
          sportType: 'football',
        )).called(1);
      });

      test('handles empty squads list', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => []);

        final result = await useCase.execute(isGuest: true);

        expect(result, isEmpty);
      });

      test('handles user with no squad memberships', () async {
        const userId = 'user-123';

        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);
        when(mockRepository.getUserSquads(userId))
            .thenAnswer((_) async => []);

        final result = await useCase.execute(userId: userId, isGuest: false);

        expect(result.length, equals(2));
        expect(result[0].role, equals(SquadRole.none));
        expect(result[1].role, equals(SquadRole.none));
      });

      test('correctly maps multiple user squad roles', () async {
        const userId = 'user-123';
        final userSquads = [
          Squad(
            id: 'squad-1',
            ownerId: 'owner-1',
            name: 'Squad 1',
            visibility: SquadVisibility.public,
            sportType: SportType.football,
            createdAt: testDate,
            memberCount: 5,
            role: SquadRole.owner,
          ),
          Squad(
            id: 'squad-2',
            ownerId: 'owner-2',
            name: 'Squad 2',
            visibility: SquadVisibility.private,
            sportType: SportType.football,
            createdAt: testDate,
            memberCount: 3,
            role: SquadRole.admin,
          ),
        ];

        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);
        when(mockRepository.getUserSquads(userId))
            .thenAnswer((_) async => userSquads);

        final result = await useCase.execute(userId: userId, isGuest: false);

        expect(result[0].role, equals(SquadRole.owner));
        expect(result[1].role, equals(SquadRole.admin));
      });

      test('propagates repository exceptions', () async {
        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenThrow(Exception('Database error'));

        await expectLater(
          useCase.execute(isGuest: true),
          throwsException,
        );
      });

      test('handles getUserSquads exception gracefully', () async {
        const userId = 'user-123';

        when(mockRepository.getSquads(
          visibility: anyNamed('visibility'),
          searchQuery: anyNamed('searchQuery'),
          sportType: anyNamed('sportType'),
        )).thenAnswer((_) async => testSquads);
        when(mockRepository.getUserSquads(userId))
            .thenThrow(Exception('User squads error'));

        await expectLater(
          useCase.execute(userId: userId, isGuest: false),
          throwsException,
        );
      });
    });
  });
}