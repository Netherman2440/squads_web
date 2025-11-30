import 'package:app/features/squads/domain/entities/user_squad_role.dart';

class SquadMember {
  final String squadId;
  final SquadRole role;
  final String userId;
  final String email;

  const SquadMember({
    required this.squadId,
    required this.role,
    required this.userId,
    required this.email,
  });

  factory SquadMember.fromMap(Map<String, dynamic> map) {
    final userData = map['users'] as Map<String, dynamic>?;
    final email =
        userData?['email'] as String? ?? map['email'] as String? ?? '';

    return SquadMember(
      squadId: map['squad_id'] as String,
      role: SquadRoleParser.fromString(map['role'] as String?),
      userId: map['user_id'] as String,
      email: email,
    );
  }
}
