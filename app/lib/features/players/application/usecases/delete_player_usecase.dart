import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';

import '../../domain/repositories/player_repository.dart';

class DeletePlayerUseCase {
  final PlayerRepository _playerRepository;

  const DeletePlayerUseCase(this._playerRepository);

  Future<void> execute({required String playerId}) async {
    await _playerRepository.deletePlayer(playerId: playerId);
  }
}

final deletePlayerUseCaseProvider = Provider<DeletePlayerUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return DeletePlayerUseCase(repository);
});
