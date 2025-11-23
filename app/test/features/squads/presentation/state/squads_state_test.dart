import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/squads/presentation/state/squads_state.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';

void main() {
  group('SquadsState', () {
    late Squad testSquad1;
    late Squad testSquad2;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1);
      testSquad1 = Squad(
        id: 'squad-1',
        ownerId: 'owner-1',
        name: 'Test Squad 1',
        visibility: SquadVisibility.public,
        sportType: SportType.football,
        createdAt: testDate,
        memberCount: 5,
        role: SquadRole.member,
      );
      testSquad2 = Squad(
        id: 'squad-2',
        ownerId: 'owner-2',
        name: 'Test Squad 2',
        visibility: SquadVisibility.private,
        sportType: SportType.football,
        createdAt: testDate,
        memberCount: 3,
        role: SquadRole.owner,
      );
    });

    test('creates state with default values', () {
      const state = SquadsState();

      expect(state.isLoading, isFalse);
      expect(state.squads, isEmpty);
      expect(state.error, isNull);
    });

    test('creates state with custom values', () {
      final state = SquadsState(
        isLoading: true,
        squads: [testSquad1, testSquad2],
        error: 'Test error',
      );

      expect(state.isLoading, isTrue);
      expect(state.squads.length, equals(2));
      expect(state.error, equals('Test error'));
    });

    group('copyWith', () {
      test('returns new state with updated isLoading', () {
        const initialState = SquadsState();
        final newState = initialState.copyWith(isLoading: true);

        expect(newState.isLoading, isTrue);
        expect(newState.squads, equals(initialState.squads));
        expect(newState.error, equals(initialState.error));
      });

      test('returns new state with updated squads', () {
        const initialState = SquadsState();
        final newState = initialState.copyWith(squads: [testSquad1]);

        expect(newState.squads.length, equals(1));
        expect(newState.squads.first, equals(testSquad1));
        expect(newState.isLoading, equals(initialState.isLoading));
      });

      test('returns new state with updated error', () {
        const initialState = SquadsState();
        final newState = initialState.copyWith(error: 'New error');

        expect(newState.error, equals('New error'));
        expect(newState.isLoading, equals(initialState.isLoading));
        expect(newState.squads, equals(initialState.squads));
      });

      test('can set error to null explicitly', () {
        const initialState = SquadsState(error: 'Initial error');
        final newState = initialState.copyWith(error: null);

        expect(newState.error, isNull);
      });

      test('returns new state with all values updated', () {
        const initialState = SquadsState();
        final newState = initialState.copyWith(
          isLoading: true,
          squads: [testSquad1, testSquad2],
          error: 'Error occurred',
        );

        expect(newState.isLoading, isTrue);
        expect(newState.squads.length, equals(2));
        expect(newState.error, equals('Error occurred'));
      });

      test('returns same values when no parameters provided', () {
        final initialState = SquadsState(
          isLoading: true,
          squads: [testSquad1],
          error: 'Error',
        );
        final newState = initialState.copyWith();

        expect(newState.isLoading, equals(initialState.isLoading));
        expect(newState.squads, equals(initialState.squads));
        // Note: error will be set to null when not provided (due to copyWith implementation)
        expect(newState.error, isNull);
      });

      test('can replace squads list', () {
        final initialState = SquadsState(squads: [testSquad1]);
        final newState = initialState.copyWith(squads: [testSquad2]);

        expect(newState.squads.length, equals(1));
        expect(newState.squads.first.id, equals('squad-2'));
      });

      test('can clear squads list', () {
        final initialState = SquadsState(squads: [testSquad1, testSquad2]);
        final newState = initialState.copyWith(squads: []);

        expect(newState.squads, isEmpty);
      });

      test('toggles loading state', () {
        const loadingState = SquadsState(isLoading: true);
        final notLoadingState = loadingState.copyWith(isLoading: false);

        expect(loadingState.isLoading, isTrue);
        expect(notLoadingState.isLoading, isFalse);
      });
    });

    test('supports immutability - copyWith creates new instance', () {
      const initialState = SquadsState();
      final newState = initialState.copyWith(isLoading: true);

      expect(identical(initialState, newState), isFalse);
      expect(initialState.isLoading, isFalse);
      expect(newState.isLoading, isTrue);
    });

    test('can represent loading state with empty data', () {
      const state = SquadsState(isLoading: true);

      expect(state.isLoading, isTrue);
      expect(state.squads, isEmpty);
      expect(state.error, isNull);
    });

    test('can represent error state', () {
      const state = SquadsState(
        isLoading: false,
        error: 'Failed to load squads',
      );

      expect(state.isLoading, isFalse);
      expect(state.squads, isEmpty);
      expect(state.error, isNotNull);
    });

    test('can represent success state with data', () {
      final state = SquadsState(
        isLoading: false,
        squads: [testSquad1, testSquad2],
      );

      expect(state.isLoading, isFalse);
      expect(state.squads.length, equals(2));
      expect(state.error, isNull);
    });
  });
}