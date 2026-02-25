import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/entities/player_position.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class AddPlayerUseCase {
  final PlayerRepository _playerRepository;

  const AddPlayerUseCase(this._playerRepository);

  Future<Player> execute({
    required String squadId,
    required String name,
    String? position,
    required int baseRanking,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationFailure('Player name cannot be empty.');
    }

    if (baseRanking < 0) {
      throw const ValidationFailure('Base ranking cannot be negative.');
    }

    final trimmedPosition = position?.trim();
    final hasPosition = trimmedPosition != null && trimmedPosition.isNotEmpty;
    final normalizedPosition = normalizePlayerPositionStorageValue(
      trimmedPosition,
    );

    if (hasPosition && normalizedPosition == null) {
      throw const ValidationFailure(
        'Invalid position. Allowed values: goalkeeper, defender, middlefielder, attacker.',
      );
    }

    return await _playerRepository.addPlayer(
      squadId: squadId,
      name: name.trim(),
      position: normalizedPosition,
      baseRanking: baseRanking,
    );
  }
}

final addPlayerUseCaseProvider = Provider<AddPlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return AddPlayerUseCase(repository);
});
