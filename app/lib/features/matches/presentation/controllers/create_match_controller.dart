import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/matches/application/dto/match_details_dto.dart';
import 'package:app/features/matches/application/usecases/create_match_usecase.dart';
import 'package:app/features/matches/application/usecases/update_match_teams_usecase.dart';
import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';

part 'create_match_controller.g.dart';

@riverpod
class CreateMatchController extends _$CreateMatchController {
  @override
  AsyncValue<MatchDetailsDto?> build() {
    return const AsyncValue.data(null);
  }

  Future<MatchDetailsDto?> createMatch({
    required String squadId,
    required List<Player> homePlayers,
    required List<Player> awayPlayers,
    List<String> rankingHistoryPlayerIds = const [],
    String? homeTeamName,
    String? awayTeamName,
  }) async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      final match = await ref
          .read(createMatchUseCaseProvider)
          .execute(
            squadId: squadId,
            homePlayerIds: homePlayers.map((p) => p.playerId).toList(),
            awayPlayerIds: awayPlayers.map((p) => p.playerId).toList(),
            rankingHistoryPlayerIds: rankingHistoryPlayerIds,
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
          );

      return ref.read(getMatchUseCaseProvider).execute(matchId: match.matchId);
    });

    state = result;
    return result.asData?.value;
  }

  Future<MatchDetailsDto?> updateMatch({
    required String matchId,
    required List<Player> homePlayers,
    required List<Player> awayPlayers,
  }) async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      await ref
          .read(updateMatchTeamsUseCaseProvider)
          .execute(
            matchId: matchId,
            homePlayerIds: homePlayers.map((p) => p.playerId).toList(),
            awayPlayerIds: awayPlayers.map((p) => p.playerId).toList(),
          );
      return ref.read(getMatchUseCaseProvider).execute(matchId: matchId);
    });

    state = result;
    return result.asData?.value;
  }
}
