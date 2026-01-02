import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/get_squad_invite_link_use_case.dart';
import '../../domain/entities/invite_link.dart';

final squadInviteLinkProvider = FutureProvider.family<InviteLink?, String>((
  ref,
  squadId,
) {
  return ref.read(getSquadInviteLinkUseCaseProvider).execute(squadId);
});
