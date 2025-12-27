import '../../domain/repositories/player_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/supabase_player_repository.dart';

class UpdatePlayerPositionUseCase {
  final PlayerRepository _playerRepository;

  UpdatePlayerPositionUseCase(this._playerRepository);

  Future<void> execute({
    required String playerId,
    required String? newPosition,
  }) async {
    await _playerRepository.updatePlayer(
      playerId: playerId,
      position: newPosition,
    );
  }
}

final updatePlayerPositionUseCaseProvider = Provider<UpdatePlayerPositionUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return UpdatePlayerPositionUseCase(repository);
});

