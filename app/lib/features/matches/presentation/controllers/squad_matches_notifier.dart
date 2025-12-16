import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matches/application/usecases/get_squad_matches_usecase.dart';
import 'package:app/features/matches/domain/entities/match.dart';

class SquadMatchesNotifier extends AutoDisposeNotifier<AsyncValue<List<Match>>> {
  @override
  AsyncValue<List<Match>> build() {
    return const AsyncValue.loading();
  }

  Future<void> load({required String squadId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(getSquadMatchesUseCaseProvider).execute(squadId: squadId),
    );
  }

  Future<void> refresh({required String squadId}) async {
    await load(squadId: squadId);
  }
}

final squadMatchesNotifierProvider =
    AutoDisposeNotifierProvider<SquadMatchesNotifier, AsyncValue<List<Match>>>(
  SquadMatchesNotifier.new,
);
