import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/player_repository.dart';
import '../../infrastructure/repositories/player_repository_impl.dart';

class DeletePlayerUseCase {
  DeletePlayerUseCase(this._repository);

  final PlayerRepository _repository;

  Future<void> execute({required String playerId}) {
    return _repository.deletePlayer(playerId: playerId);
  }
}

final deletePlayerUseCaseProvider = Provider<DeletePlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return DeletePlayerUseCase(repository);
});
