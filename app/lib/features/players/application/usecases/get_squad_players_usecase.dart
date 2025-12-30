import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class GetSquadPlayersUseCase {
  final PlayerRepository _playerRepository;

  const GetSquadPlayersUseCase(this._playerRepository);

  Future<List<Player>> execute({required String squadId}) async {
    return await _playerRepository.getSquadPlayers(squadId: squadId);
  }
}

final getSquadPlayersUseCaseProvider = Provider<GetSquadPlayersUseCase>((ref) {
  final repository = ref.read(playerRepositoryProvider);
  return GetSquadPlayersUseCase(repository);
});
