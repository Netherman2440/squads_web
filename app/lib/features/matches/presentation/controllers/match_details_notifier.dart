import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/matches/domain/entities/match.dart';

part 'match_details_notifier.g.dart';

@riverpod
class MatchDetailsNotifier extends _$MatchDetailsNotifier {
  @override
  AsyncValue<Match> build(String matchId) {
    _loadMatch();
    return const AsyncValue.loading();
  }

  Future<void> _loadMatch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(getMatchUseCaseProvider).execute(matchId: matchId);
    });
  }

  Future<void> refresh() async {
    await _loadMatch();
  }
}

