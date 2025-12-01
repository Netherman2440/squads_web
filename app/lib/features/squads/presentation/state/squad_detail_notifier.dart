import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/application/get_squad_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';

final squadDetailProvider = FutureProvider.family<Squad, String>(
  (ref, squadId) async {
    final authState = ref.read(authStateProvider);
    final authEntity = authState.authEntity;

    final result = await ref.read(getSquadUseCaseProvider).execute(
          squadId: squadId,
          userId: authEntity?.userId,
          isGuest: authEntity == null || authEntity.isAnonymous,
        );

    if (result.failure != null) {
      throw result.failure!;
    }

    return result.squad!;
  },
);

