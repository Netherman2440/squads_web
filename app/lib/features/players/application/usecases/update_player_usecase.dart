import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../../infrastructure/repositories/player_repository_impl.dart';

class UpdatePlayerUseCase {
  UpdatePlayerUseCase(this._repository);

  final PlayerRepository _repository;

  Future<Player> execute({
    required String playerId,
    String? name,
    int? baseScore,
    double? score,
  }) {
    if (name != null && name.trim().isEmpty) {
      throw const ValidationFailure('Player name cannot be empty.');
    }

    if (name == null && baseScore == null && score == null) {
      throw const ValidationFailure('No updates provided for the player.');
    }

    return _repository.updatePlayer(
      playerId: playerId,
      name: name?.trim(),
      baseScore: baseScore,
      score: score,
    );
  }
}

final updatePlayerUseCaseProvider = Provider<UpdatePlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return UpdatePlayerUseCase(repository);
});
