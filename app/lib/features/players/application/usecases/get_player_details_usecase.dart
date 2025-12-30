import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class GetPlayerDetailsUseCase {
  final PlayerRepository _playerRepository;

  const GetPlayerDetailsUseCase(this._playerRepository);

  Future<Player> execute({required String playerId}) async {
    // TODO: Extend this with additional aggregation logic
    // (e.g. match stats) when PlayerDetailsPage is implemented.
    return await _playerRepository.getPlayer(playerId: playerId);
  }
}

final getPlayerDetailsUseCaseProvider = Provider<GetPlayerDetailsUseCase>((
  ref,
) {
  final repository = ref.read(playerRepositoryProvider);
  return GetPlayerDetailsUseCase(repository);
});
