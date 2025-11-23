import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';

void main() {
  group('SquadVisibility', () {
    group('fromString', () {
      test('returns private when value is "private"', () {
        expect(
          SquadVisibilityParser.fromString('private'),
          equals(SquadVisibility.private),
        );
      });

      test('returns private when value is "PRIVATE" (case insensitive)', () {
        expect(
          SquadVisibilityParser.fromString('PRIVATE'),
          equals(SquadVisibility.private),
        );
      });

      test('returns public when value is "public"', () {
        expect(
          SquadVisibilityParser.fromString('public'),
          equals(SquadVisibility.public),
        );
      });

      test('returns public when value is null', () {
        expect(
          SquadVisibilityParser.fromString(null),
          equals(SquadVisibility.public),
        );
      });

      test('returns public when value is empty string', () {
        expect(
          SquadVisibilityParser.fromString(''),
          equals(SquadVisibility.public),
        );
      });

      test('returns public for unknown value', () {
        expect(
          SquadVisibilityParser.fromString('unknown'),
          equals(SquadVisibility.public),
        );
      });
    });

    test('label returns correct string', () {
      expect(SquadVisibility.public.label, equals('public'));
      expect(SquadVisibility.private.label, equals('private'));
    });
  });

  group('SportType', () {
    group('fromString', () {
      test('returns football when value is "football"', () {
        expect(
          SportTypeParser.fromString('football'),
          equals(SportType.football),
        );
      });

      test('returns football when value is "FOOTBALL" (case insensitive)', () {
        expect(
          SportTypeParser.fromString('FOOTBALL'),
          equals(SportType.football),
        );
      });

      test('returns football when value is null (default)', () {
        expect(
          SportTypeParser.fromString(null),
          equals(SportType.football),
        );
      });

      test('returns football for unknown value (default)', () {
        expect(
          SportTypeParser.fromString('unknown'),
          equals(SportType.football),
        );
      });
    });

    test('label returns correct string', () {
      expect(SportType.football.label, equals('football'));
    });
  });

  group('Squad', () {
    late Squad testSquad;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0);
      testSquad = Squad(
        id: 'squad-1',
        ownerId: 'owner-1',
        name: 'Test Squad',
        visibility: SquadVisibility.public,
        sportType: SportType.football,
        createdAt: testDate,
        memberCount: 5,
        role: SquadRole.member,
      );
    });

    test('creates squad with required parameters', () {
      expect(testSquad.id, equals('squad-1'));
      expect(testSquad.ownerId, equals('owner-1'));
      expect(testSquad.name, equals('Test Squad'));
      expect(testSquad.visibility, equals(SquadVisibility.public));
      expect(testSquad.sportType, equals(SportType.football));
      expect(testSquad.createdAt, equals(testDate));
      expect(testSquad.memberCount, equals(5));
      expect(testSquad.role, equals(SquadRole.member));
    });

    test('creates squad with default role as none', () {
      final squad = Squad(
        id: 'squad-1',
        ownerId: 'owner-1',
        name: 'Test Squad',
        visibility: SquadVisibility.public,
        sportType: SportType.football,
        createdAt: testDate,
        memberCount: 5,
      );

      expect(squad.role, equals(SquadRole.none));
    });

    group('copyWith', () {
      test('returns new instance with updated id', () {
        final updated = testSquad.copyWith(id: 'new-id');
        expect(updated.id, equals('new-id'));
        expect(updated.name, equals(testSquad.name));
      });

      test('returns new instance with updated name', () {
        final updated = testSquad.copyWith(name: 'New Name');
        expect(updated.name, equals('New Name'));
        expect(updated.id, equals(testSquad.id));
      });

      test('returns new instance with updated visibility', () {
        final updated = testSquad.copyWith(visibility: SquadVisibility.private);
        expect(updated.visibility, equals(SquadVisibility.private));
      });

      test('returns new instance with updated role', () {
        final updated = testSquad.copyWith(role: SquadRole.owner);
        expect(updated.role, equals(SquadRole.owner));
      });

      test('returns new instance with updated memberCount', () {
        final updated = testSquad.copyWith(memberCount: 10);
        expect(updated.memberCount, equals(10));
      });

      test('returns same values when no parameters provided', () {
        final updated = testSquad.copyWith();
        expect(updated.id, equals(testSquad.id));
        expect(updated.name, equals(testSquad.name));
        expect(updated.visibility, equals(testSquad.visibility));
        expect(updated.role, equals(testSquad.role));
      });
    });

    group('fromMap', () {
      test('creates squad from valid map with member_count', () {
        final map = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'public',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
          'member_count': 5,
          'role': 'member',
        };

        final squad = Squad.fromMap(map);

        expect(squad.id, equals('squad-1'));
        expect(squad.ownerId, equals('owner-1'));
        expect(squad.name, equals('Test Squad'));
        expect(squad.visibility, equals(SquadVisibility.public));
        expect(squad.sportType, equals(SportType.football));
        expect(squad.memberCount, equals(5));
        expect(squad.role, equals(SquadRole.member));
      });

      test('creates squad from map with user_squads count', () {
        final map = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'private',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
          'user_squads': [
            {'count': 10}
          ],
        };

        final squad = Squad.fromMap(map);

        expect(squad.memberCount, equals(10));
        expect(squad.visibility, equals(SquadVisibility.private));
      });

      test('handles member_count as string', () {
        final map = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'public',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
          'member_count': '7',
        };

        final squad = Squad.fromMap(map);
        expect(squad.memberCount, equals(7));
      });

      test('handles missing member_count gracefully', () {
        final map = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'public',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
        };

        final squad = Squad.fromMap(map);
        expect(squad.memberCount, equals(0));
      });

      test('handles invalid member_count string', () {
        final map = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'public',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
          'member_count': 'invalid',
        };

        final squad = Squad.fromMap(map);
        expect(squad.memberCount, equals(0));
      });

      test('parses visibility correctly', () {
        final publicMap = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'public',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
          'member_count': 0,
        };

        final privateMap = {...publicMap, 'visibility': 'private'};

        expect(Squad.fromMap(publicMap).visibility, equals(SquadVisibility.public));
        expect(Squad.fromMap(privateMap).visibility, equals(SquadVisibility.private));
      });

      test('parses role correctly', () {
        final map = {
          'id': 'squad-1',
          'owner_id': 'owner-1',
          'name': 'Test Squad',
          'visibility': 'public',
          'sport_type': 'football',
          'created_at': '2024-01-01T12:00:00.000Z',
          'member_count': 0,
          'role': 'owner',
        };

        final squad = Squad.fromMap(map);
        expect(squad.role, equals(SquadRole.owner));
      });
    });

    group('toMap', () {
      test('converts squad to map correctly', () {
        final map = testSquad.toMap();

        expect(map['id'], equals('squad-1'));
        expect(map['owner_id'], equals('owner-1'));
        expect(map['name'], equals('Test Squad'));
        expect(map['visibility'], equals('public'));
        expect(map['sport_type'], equals('football'));
        expect(map['created_at'], equals(testDate.toIso8601String()));
        expect(map['member_count'], equals(5));
        expect(map['role'], equals('member'));
      });

      test('converts private squad correctly', () {
        final privateSquad = testSquad.copyWith(
          visibility: SquadVisibility.private,
          role: SquadRole.owner,
        );
        final map = privateSquad.toMap();

        expect(map['visibility'], equals('private'));
        expect(map['role'], equals('owner'));
      });
    });

    group('fromMap and toMap round-trip', () {
      test('preserves all data through serialization', () {
        final original = testSquad.toMap();
        final deserialized = Squad.fromMap(original);
        final reserialize = deserialized.toMap();

        expect(reserialize, equals(original));
      });
    });
  });
}