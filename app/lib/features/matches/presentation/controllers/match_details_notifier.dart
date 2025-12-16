import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/matches/domain/entities/match.dart';

class MatchDetailsNotifier extends AutoDisposeNotifier<AsyncValue<Match>> {
  @override
  AsyncValue<Match> build() {
    return const AsyncValue.loading();
  }

  Future<void> load({required String matchId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(getMatchUseCaseProvider).execute(matchId: matchId),
    );
  }
}

final matchDetailsNotifierProvider =
    AutoDisposeNotifierProvider<MatchDetailsNotifier, AsyncValue<Match>>(
  MatchDetailsNotifier.new,
);
