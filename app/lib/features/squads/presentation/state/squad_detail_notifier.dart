import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/features/squads/application/get_squad_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';

final _logger = Logger('SquadDetailProvider');

final squadDetailProvider = FutureProvider.family<Squad, String>((
  ref,
  squadId,
) async {
  _logger.fine('Loading squad details for squadId=$squadId');

  try {
    final squad = await ref
        .watch(getSquadUseCaseProvider)
        .execute(squadId: squadId);
    _logger.fine('Loaded squad $squadId with role=${squad.role}');
    return squad;
  } catch (e, stack) {
    _logger.severe('Failed to load squad $squadId', e, stack);
    rethrow;
  }
});
