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
        return 'Właściciel';
      case SquadRole.admin:
        return 'Administrator';
      case SquadRole.member:
        return 'Członek';
      case SquadRole.pending:
        return 'Oczekuje';
      case SquadRole.invited:
        return 'Zaproszony';
      case SquadRole.declined:
        return 'Odrzucony';
      case SquadRole.removed:
        return 'Usunięty';
      case SquadRole.none:
        return 'Brak';
      case SquadRole.guest:
        return 'Gość';
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
