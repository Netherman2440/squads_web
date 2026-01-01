import '../../domain/repositories/player_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/supabase_player_repository.dart';

class UpdatePlayerNameUseCase {
  final PlayerRepository _playerRepository;

  UpdatePlayerNameUseCase(this._playerRepository);

  Future<void> execute({
    required String playerId,
    required String newName,
  }) async {
    await _playerRepository.updatePlayer(playerId: playerId, name: newName);
  }
}

final updatePlayerNameUseCaseProvider = Provider<UpdatePlayerNameUseCase>((
  ref,
) {
  final repository = ref.read(playerRepositoryProvider);
  return UpdatePlayerNameUseCase(repository);
});
