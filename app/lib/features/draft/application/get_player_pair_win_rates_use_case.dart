import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/draft/domain/entities/head_to_head_win_rate.dart';
import 'package:app/features/draft/domain/repositories/draft_stats_repository.dart';
import 'package:app/features/draft/infrastructure/repositories/supabase_draft_stats_repository.dart';

class GetPlayerPairWinRatesUseCase {
  final DraftStatsRepository _repository;

  GetPlayerPairWinRatesUseCase(this._repository);

  Future<List<HeadToHeadWinRate>> execute({required List<String> playerIds}) {
    return _repository.getPlayerPairWinRates(playerIds: playerIds);
  }
}

final getPlayerPairWinRatesUseCaseProvider =
    Provider<GetPlayerPairWinRatesUseCase>((ref) {
      return GetPlayerPairWinRatesUseCase(
        ref.read(draftStatsRepositoryProvider),
      );
    });
