import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/invite_link.dart';
import '../domain/repositories/invite_links_repository.dart';
import '../infrastructure/repositories/supabase_invite_links_repository.dart';

class GetSquadInviteLinkUseCase {
  final InviteLinksRepository _repository;

  GetSquadInviteLinkUseCase(this._repository);

  Future<InviteLink?> execute(String squadId) async {
    final link = await _repository.getInviteLink(squadId);
    if (link == null || link.isExpired) {
      return null;
    }
    return link;
  }
}

final getSquadInviteLinkUseCaseProvider = Provider<GetSquadInviteLinkUseCase>((
  ref,
) {
  final repository = ref.read(inviteLinksRepositoryProvider);
  return GetSquadInviteLinkUseCase(repository);
});
