import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/application/get_squad_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';

final _logger = Logger('SquadDetailProvider');

final squadDetailProvider = FutureProvider.family<Squad, String>((
  ref,
  squadId,
) async {
  final authState = ref.watch(authStateProvider);
  final authEntity = authState.value;

  final userId = authEntity?.userId;
  final isGuest = authEntity == null || authEntity.isAnonymous;

  _logger.fine(
    'Loading squad details for squadId=$squadId, userId=$userId, '
    'isGuest=$isGuest',
  );

  try {
    final squad = await ref
        .read(getSquadUseCaseProvider)
        .execute(squadId: squadId, userId: userId, isGuest: isGuest);
    _logger.fine(
      'Loaded squad $squadId with role=${squad.role} for userId=$userId',
    );
    return squad;
  } catch (e, stack) {
    _logger.severe(
      'Failed to load squad $squadId for userId=$userId, isGuest=$isGuest',
      e,
      stack,
    );
    rethrow;
  }
});
