import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../../infrastructure/repositories/player_repository_impl.dart';

class AddPlayerUseCase {
  AddPlayerUseCase(this._repository);

  final PlayerRepository _repository;

  Future<Player> execute({
    required String squadId,
    required String name,
    String? position,
    required int baseScore,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationFailure('Player name cannot be empty.');
    }

    return _repository.addPlayer(
      squadId: squadId,
      name: name.trim(),
      position: position?.trim().isEmpty == true ? null : position?.trim(),
      baseScore: baseScore,
    );
  }
}

final addPlayerUseCaseProvider = Provider<AddPlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return AddPlayerUseCase(repository);
});
