import '../entities/invite_link.dart';

abstract class InviteLinksRepository {
  Future<InviteLink> createInviteLink(
    String squadId,
    String code,
    Duration validFor,
  );

  Future<InviteLink?> getInviteLink(String squadId);
}
