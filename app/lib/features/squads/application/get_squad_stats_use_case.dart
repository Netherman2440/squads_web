import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/features/squads/domain/entities/squad_stats.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';
import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

class GetSquadStatsUseCase {
  final SquadRepository _squadRepository;
  final Logger _logger = Logger('GetSquadStatsUseCase');

  GetSquadStatsUseCase(this._squadRepository);

  Future<SquadStats> execute({required String squadId}) async {
    try {
      _logger.fine('Fetching squad stats for squadId=$squadId');
      final stats = await _squadRepository.getSquadStats(squadId);
      _logger.fine('Fetched squad stats for squadId=$squadId');
      return stats;
    } catch (e, stack) {
      _logger.severe(
        'Failed to fetch squad stats for squadId=$squadId',
        e,
        stack,
      );
      rethrow;
    }
  }
}

final getSquadStatsUseCaseProvider = Provider<GetSquadStatsUseCase>((ref) {
  final squadRepository = ref.read(squadRepositoryProvider);
  return GetSquadStatsUseCase(squadRepository);
});
