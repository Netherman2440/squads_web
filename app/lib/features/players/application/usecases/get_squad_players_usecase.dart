import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../../infrastructure/repositories/player_repository_impl.dart';

class GetSquadPlayersUseCase {
  GetSquadPlayersUseCase(this._repository);

  final PlayerRepository _repository;

  Future<List<Player>> execute({required String squadId}) {
    return _repository.getSquadPlayers(squadId: squadId);
  }
}

final getSquadPlayersUseCaseProvider = Provider<GetSquadPlayersUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return GetSquadPlayersUseCase(repository);
});
