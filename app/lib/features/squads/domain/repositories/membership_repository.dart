import '../entities/membership.dart';
import '../entities/user_squad_role.dart';

abstract class MembershipRepository {
  Future<List<Membership>> getMembershipsForUser(String userId);

  Future<List<Membership>> getMembershipsForSquad(String squadId);

  Future<void> updateMemberRole(
    String squadId,
    String userId,
    SquadRole newRole,
  );

  Future<void> removeMember(String squadId, String userId);
}
