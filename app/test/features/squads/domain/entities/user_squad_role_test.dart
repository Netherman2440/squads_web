import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';

void main() {
  group('SquadRole', () {
    group('fromString', () {
      test('returns owner for "owner"', () {
        expect(SquadRoleParser.fromString('owner'), equals(SquadRole.owner));
      });

      test('returns admin for "admin"', () {
        expect(SquadRoleParser.fromString('admin'), equals(SquadRole.admin));
      });

      test('returns member for "member"', () {
        expect(SquadRoleParser.fromString('member'), equals(SquadRole.member));
      });

      test('returns pending for "pending"', () {
        expect(SquadRoleParser.fromString('pending'), equals(SquadRole.pending));
      });

      test('returns invited for "invited"', () {
        expect(SquadRoleParser.fromString('invited'), equals(SquadRole.invited));
      });

      test('returns declined for "declined"', () {
        expect(SquadRoleParser.fromString('declined'), equals(SquadRole.declined));
      });

      test('returns removed for "removed"', () {
        expect(SquadRoleParser.fromString('removed'), equals(SquadRole.removed));
      });

      test('returns none for null', () {
        expect(SquadRoleParser.fromString(null), equals(SquadRole.none));
      });

      test('returns none for empty string', () {
        expect(SquadRoleParser.fromString(''), equals(SquadRole.none));
      });

      test('returns none for unknown value', () {
        expect(SquadRoleParser.fromString('unknown'), equals(SquadRole.none));
      });

      test('is case insensitive', () {
        expect(SquadRoleParser.fromString('OWNER'), equals(SquadRole.owner));
        expect(SquadRoleParser.fromString('Admin'), equals(SquadRole.admin));
        expect(SquadRoleParser.fromString('MEMBER'), equals(SquadRole.member));
      });
    });

    group('label', () {
      test('returns correct label for owner', () {
        expect(SquadRole.owner.label, equals('Owner'));
      });

      test('returns correct label for admin', () {
        expect(SquadRole.admin.label, equals('Admin'));
      });

      test('returns correct label for member', () {
        expect(SquadRole.member.label, equals('Member'));
      });

      test('returns correct label for pending', () {
        expect(SquadRole.pending.label, equals('Pending'));
      });

      test('returns correct label for invited', () {
        expect(SquadRole.invited.label, equals('Invited'));
      });

      test('returns correct label for declined', () {
        expect(SquadRole.declined.label, equals('Declined'));
      });

      test('returns correct label for removed', () {
        expect(SquadRole.removed.label, equals('Removed'));
      });

      test('returns correct label for none', () {
        expect(SquadRole.none.label, equals('None'));
      });
    });

    test('all enum values have unique labels', () {
      final labels = SquadRole.values.map((role) => role.label).toSet();
      expect(labels.length, equals(SquadRole.values.length));
    });
  });

  group('UserSquadRole', () {
    test('creates instance with required parameters', () {
      const userSquadRole = UserSquadRole(
        squadId: 'squad-123',
        role: SquadRole.member,
      );

      expect(userSquadRole.squadId, equals('squad-123'));
      expect(userSquadRole.role, equals(SquadRole.member));
    });

    group('fromMap', () {
      test('creates UserSquadRole from valid map', () {
        final map = {
          'squad_id': 'squad-456',
          'role': 'owner',
        };

        final userSquadRole = UserSquadRole.fromMap(map);

        expect(userSquadRole.squadId, equals('squad-456'));
        expect(userSquadRole.role, equals(SquadRole.owner));
      });

      test('handles different role values', () {
        final roles = [
          'owner',
          'admin',
          'member',
          'pending',
          'invited',
          'declined',
          'removed',
        ];

        for (final roleStr in roles) {
          final map = {
            'squad_id': 'squad-123',
            'role': roleStr,
          };

          final userSquadRole = UserSquadRole.fromMap(map);
          expect(userSquadRole.role, equals(SquadRoleParser.fromString(roleStr)));
        }
      });

      test('handles null role', () {
        final map = {
          'squad_id': 'squad-123',
          'role': null,
        };

        final userSquadRole = UserSquadRole.fromMap(map);
        expect(userSquadRole.role, equals(SquadRole.none));
      });

      test('handles missing role field', () {
        final map = {
          'squad_id': 'squad-123',
        };

        final userSquadRole = UserSquadRole.fromMap(map);
        expect(userSquadRole.role, equals(SquadRole.none));
      });
    });

    test('two instances with same values are not equal (no equality override)', () {
      const role1 = UserSquadRole(
        squadId: 'squad-123',
        role: SquadRole.member,
      );
      const role2 = UserSquadRole(
        squadId: 'squad-123',
        role: SquadRole.member,
      );

      // UserSquadRole doesn't override equality, so these should be different instances
      expect(identical(role1, role2), isFalse);
    });
  });
}