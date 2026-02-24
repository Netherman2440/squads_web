import '../../domain/repositories/player_repository.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/entities/player_position.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/supabase_player_repository.dart';

class UpdatePlayerPositionUseCase {
  final PlayerRepository _playerRepository;

  UpdatePlayerPositionUseCase(this._playerRepository);

  Future<void> execute({
    required String playerId,
    required String? newPosition,
  }) async {
    final trimmedPosition = newPosition?.trim();
    final hasPosition = trimmedPosition != null && trimmedPosition.isNotEmpty;
    final normalizedPosition = normalizePlayerPositionStorageValue(
      trimmedPosition,
    );

    if (hasPosition && normalizedPosition == null) {
      throw const ValidationFailure(
        'Invalid position. Allowed values: goalkeeper, defender, middlefielder, attacker.',
      );
    }

    await _playerRepository.updatePlayer(
      playerId: playerId,
      position: normalizedPosition,
    );
  }
}

final updatePlayerPositionUseCaseProvider =
    Provider<UpdatePlayerPositionUseCase>((ref) {
      final repository = ref.read(playerRepositoryProvider);
      return UpdatePlayerPositionUseCase(repository);
    });
