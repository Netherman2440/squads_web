import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/application/usecases/get_player_tournaments_usecase.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';

typedef PlayerTournamentsParams = ({String squadId, String playerId});

final playerTournamentsProvider =
    FutureProvider.family<List<Tournament>, PlayerTournamentsParams>((
      ref,
      params,
    ) async {
      final useCase = ref.read(getPlayerTournamentsUseCaseProvider);
      return useCase.execute(
        squadId: params.squadId,
        playerId: params.playerId,
      );
    });
