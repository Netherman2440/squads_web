import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/users/domain/entities/user.dart';

class UserMembershipItem {
  final String squadId;
  final String squadName;
  final SquadRole role;

  const UserMembershipItem({
    required this.squadId,
    required this.squadName,
    required this.role,
  });
}

class UserProfileSummary {
  final User user;
  final List<UserMembershipItem> memberships;

  const UserProfileSummary({
    required this.user,
    required this.memberships,
  });
}


