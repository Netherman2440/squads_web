import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
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

    return await _playerRepository.addPlayer(
      squadId: squadId,
      name: name.trim(),
      position: position?.trim(),
      baseRanking: baseRanking,
    );
  }
}

final addPlayerUseCaseProvider = Provider<AddPlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return AddPlayerUseCase(repository);
});


