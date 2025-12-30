import 'package:app/features/squads/domain/entities/user_squad_role.dart';

class Membership {
  final String userId;
  final String squadId;
  final SquadRole role;
  final DateTime createdAt;

  const Membership({
    required this.userId,
    required this.squadId,
    required this.role,
    required this.createdAt,
  });

  Membership.empty()
    : userId = '',
      squadId = '',
      role = SquadRole.none,
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isEmpty => userId.isEmpty || squadId.isEmpty;
}
