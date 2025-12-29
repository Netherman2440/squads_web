import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/matches/application/usecases/update_match_score_usecase.dart';
import 'package:app/features/matches/application/usecases/delete_match_usecase.dart';
import 'package:app/features/matches/application/usecases/update_match_teams_usecase.dart';
import 'package:app/features/matches/application/usecases/rematch_usecase.dart';
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

  Future<void> updateScore(String squadId, int homeScore, int awayScore) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedMatch = await ref
          .read(updateMatchScoreUseCaseProvider)
          .execute(
            matchId: matchId,
            squadId: squadId,
            homeScore: homeScore,
            awayScore: awayScore,
          );
      return updatedMatch;
    });
  }

  Future<void> updateTeams(
    List<String> homePlayerIds,
    List<String> awayPlayerIds,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(updateMatchTeamsUseCaseProvider)
          .execute(
            matchId: matchId,
            homePlayerIds: homePlayerIds,
            awayPlayerIds: awayPlayerIds,
          );
      // Reload to get fresh state (rankings etc)
      return ref.read(getMatchUseCaseProvider).execute(matchId: matchId);
    });
  }

  Future<Match> rematch() async {
    // Returns the new match. UI handles navigation.
    final newMatch = await ref
        .read(rematchUseCaseProvider)
        .execute(matchId: matchId);
    return newMatch;
  }

  Future<void> deleteMatch() async {
    // We don't update state to data here because match is gone.
    // UI should listen and pop.
    // But we can set loading.
    state = const AsyncValue.loading();
    await AsyncValue.guard(() async {
      await ref.read(deleteMatchUseCaseProvider).execute(matchId: matchId);
      // We might return null or throw specific exception to signal deletion?
      // Or just let the UI handle the success of this future.
      // However, updating state to "data" is wrong if it doesn't exist.
      // We can leave it as loading or set error if failed.
    });
  }
}
