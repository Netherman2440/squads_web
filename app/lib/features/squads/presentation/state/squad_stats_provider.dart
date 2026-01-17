import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/features/squads/application/get_squad_stats_use_case.dart';
import 'package:app/features/squads/domain/entities/squad_stats.dart';

final _logger = Logger('SquadStatsProvider');

final squadStatsProvider = FutureProvider.family<SquadStats, String>(
  (ref, squadId) async {
    _logger.fine('Loading squad stats for squadId=$squadId');

    try {
      final stats = await ref
          .watch(getSquadStatsUseCaseProvider)
          .execute(squadId: squadId);
      _logger.fine('Loaded squad stats for squadId=$squadId');
      return stats;
    } catch (e, stack) {
      _logger.severe(
        'Failed to load squad stats for squadId=$squadId',
        e,
        stack,
      );
      rethrow;
    }
  },
);
