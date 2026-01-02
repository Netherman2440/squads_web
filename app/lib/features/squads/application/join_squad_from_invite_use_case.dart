import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/invite_code_storage.dart';
import '../domain/repositories/squad_repository.dart';
import '../infrastructure/repositories/supabase_squad_repository.dart';
import '../infrastructure/storage/invite_code_storage.dart';

class JoinSquadFromInviteUseCase {
  final SquadRepository _squadRepository;
  final InviteCodeStorage _inviteCodeStorage;

  JoinSquadFromInviteUseCase(this._squadRepository, this._inviteCodeStorage);

  /// Returns joined squadId or null if no invite code was pending.
  Future<String?> execute() async {
    final code = await _inviteCodeStorage.readCode();
    if (code == null) {
      return null;
    }

    try {
      final squadId = await _squadRepository.joinSquadByCode(code);
      await _inviteCodeStorage.clear();
      return squadId;
    } catch (_) {
      await _inviteCodeStorage.clear();
      rethrow;
    }
  }
}

final joinSquadFromInviteUseCaseProvider = Provider<JoinSquadFromInviteUseCase>(
  (ref) {
    final repository = ref.read(squadRepositoryProvider);
    final storage = ref.read(inviteCodeStorageProvider);
    return JoinSquadFromInviteUseCase(repository, storage);
  },
);
