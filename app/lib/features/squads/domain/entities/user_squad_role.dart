enum SquadRole {
  none,
  owner,
  admin,
  member,
  pending,
  invited,
  declined,
  removed,
  guest,
}

extension SquadRoleParser on SquadRole {
  static SquadRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'owner':
        return SquadRole.owner;
      case 'admin':
        return SquadRole.admin;
      case 'member':
        return SquadRole.member;
      case 'pending':
        return SquadRole.pending;
      case 'invited':
        return SquadRole.invited;
      case 'declined':
        return SquadRole.declined;
      case 'removed':
        return SquadRole.removed;
      case 'guest':
        return SquadRole.guest;
      default:
        return SquadRole.none;
    }
  }

  String get label {
    switch (this) {
      case SquadRole.owner:
        return 'Owner';
      case SquadRole.admin:
        return 'Admin';
      case SquadRole.member:
        return 'Member';
      case SquadRole.pending:
        return 'Pending';
      case SquadRole.invited:
        return 'Invited';
      case SquadRole.declined:
        return 'Declined';
      case SquadRole.removed:
        return 'Removed';
      case SquadRole.none:
        return 'None';
      case SquadRole.guest:
        return 'Guest';
    }
  }
}

class UserSquadRole {
  final String squadId;
  final SquadRole role;

  const UserSquadRole({required this.squadId, required this.role});

  factory UserSquadRole.fromMap(Map<String, dynamic> map) => UserSquadRole(
    squadId: map['squad_id'] as String,
    role: SquadRoleParser.fromString(map['role'] as String?),
  );
}
