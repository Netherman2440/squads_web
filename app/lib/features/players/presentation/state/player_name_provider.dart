import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/application/usecases/get_player_details_usecase.dart';

final playerNameProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  playerId,
) async {
  final getPlayerDetails = ref.read(getPlayerDetailsUseCaseProvider);
  final player = await getPlayerDetails.execute(playerId: playerId);
  return player.name;
});
