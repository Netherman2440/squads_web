import '../entities/membership.dart';

abstract class MembershipRepository {
  Future<List<Membership>> getMembershipsForUser(String userId);

  Future<List<Membership>> getMembershipsForSquad(String squadId);
}


