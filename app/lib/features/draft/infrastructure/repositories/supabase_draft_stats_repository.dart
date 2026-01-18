import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/global_dependencies.dart';
import 'package:app/core/error/supabase_error_extension.dart';
import 'package:app/features/draft/domain/entities/head_to_head_win_rate.dart';
import 'package:app/features/draft/domain/repositories/draft_stats_repository.dart';

class SupabaseDraftStatsRepository implements DraftStatsRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseDraftStatsRepository');

  SupabaseDraftStatsRepository(this._supabase);

  @override
  Future<List<HeadToHeadWinRate>> getPlayerPairWinRates({
    required List<String> playerIds,
  }) async {
    if (playerIds.isEmpty) {
      return const [];
    }

    try {
      final response = await _supabase.rpc(
        'get_player_pair_win_rates',
        params: {'p_player_ids': playerIds},
      );

      final List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map) {
        data = [response];
      } else {
        return const [];
      }

      return data
          .map(
            (row) => HeadToHeadWinRate.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
    } catch (e, stack) {
      _logger.severe('Failed to fetch player pair win rates', e, stack);
      throw e.toFailure();
    }
  }
}

final draftStatsRepositoryProvider = Provider<DraftStatsRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseDraftStatsRepository(supabase);
});
