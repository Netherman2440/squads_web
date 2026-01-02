import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/app_config.dart';

import '../domain/entities/invite_link.dart';
import '../domain/repositories/invite_links_repository.dart';
import '../infrastructure/repositories/supabase_invite_links_repository.dart';

class GenerateInviteLinkUseCase {
  final InviteLinksRepository _repository;

  GenerateInviteLinkUseCase(this._repository);

  Future<InviteLink> execute(String squadId) {
    final code = const Uuid().v4();
    return _repository.createInviteLink(
      squadId,
      code,
      AppConfig.inviteLinkValidity,
    );
  }
}

final generateInviteLinkUseCaseProvider = Provider<GenerateInviteLinkUseCase>((
  ref,
) {
  final repository = ref.read(inviteLinksRepositoryProvider);
  return GenerateInviteLinkUseCase(repository);
});
