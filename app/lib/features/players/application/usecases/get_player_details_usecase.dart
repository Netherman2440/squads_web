import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../../infrastructure/repositories/player_repository_impl.dart';

class GetPlayerDetailsUseCase {
  GetPlayerDetailsUseCase(this._repository);

  final PlayerRepository _repository;

  Future<Player> execute({required String playerId}) {
    // TODO: Implement when PlayerDetailsPage is introduced.
    throw UnimplementedError('Player details flow is not implemented yet.');
  }
}

final getPlayerDetailsUseCaseProvider = Provider<GetPlayerDetailsUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return GetPlayerDetailsUseCase(repository);
});
