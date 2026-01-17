import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/players/application/usecases/get_player_matches_usecase.dart';

final playerMatchesProvider =
    FutureProvider.family<List<Match>, String>((ref, playerId) async {
  final useCase = ref.read(getPlayerMatchesUseCaseProvider);
  return useCase.execute(playerId: playerId);
});
