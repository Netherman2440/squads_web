import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class UpdatePlayerUseCase {
  final PlayerRepository _playerRepository;

  const UpdatePlayerUseCase(this._playerRepository);

  Future<Player> execute({
    required String playerId,
    String? name,
    double? score,
  }) async {
    if ((name == null || name.trim().isEmpty) && score == null) {
      throw const ValidationFailure(
        'At least one field (name or score) must be provided.',
      );
    }

    if (score != null && score < 0) {
      throw const ValidationFailure('Score cannot be negative.');
    }

    return await _playerRepository.updatePlayer(
      playerId: playerId,
      name: name?.trim(),
      score: score,
    );
  }
}

final updatePlayerUseCaseProvider = Provider<UpdatePlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return UpdatePlayerUseCase(repository);
});


