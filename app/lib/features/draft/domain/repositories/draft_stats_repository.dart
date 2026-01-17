import 'package:app/features/draft/domain/entities/head_to_head_win_rate.dart';

abstract class DraftStatsRepository {
  Future<List<HeadToHeadWinRate>> getPlayerPairWinRates({
    required List<String> playerIds,
  });
}
