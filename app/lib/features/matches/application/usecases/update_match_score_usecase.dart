import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/infrastructure/repositories/supabase_match_repository.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_player_repository.dart';
import 'package:app/features/players/infrastructure/repositories/supabase_ranking_repository.dart';
import 'package:app/features/squads/application/get_squad_use_case.dart';

class UpdateMatchScoreUseCase {
  final MatchRepository _matchRepository;
  final RankingRepository _rankingRepository;
  final PlayerRepository _playerRepository;
  final GetSquadUseCase _getSquadUseCase;

  UpdateMatchScoreUseCase(
    this._matchRepository,
    this._rankingRepository,
    this._playerRepository,
    this._getSquadUseCase,
  );

  Future<Match> execute({
    required String matchId,
    required String squadId,
    required int homeScore,
    required int awayScore,
  }) async {
    // 1. Get Squad Settings
    final squad = await _getSquadUseCase.execute(
      squadId: squadId,
      userId: null,
      isGuest: true,
    );

    // 2. Update Match Score
    final match = await _matchRepository.updateMatchScore(
      matchId: matchId,
      homeScore: homeScore,
      awayScore: awayScore,
    );

    // 3. Update Rankings if enabled
    if (squad.rankingUpdate) {
      final delta =
          (homeScore - awayScore).toDouble() * squad.rankingMultiplier;

      if (match.homeTeam == null || match.awayTeam == null) {
        throw const ServerFailure('Teams not found in match');
      }

      final futures = <Future>[];

      for (final player in match.homeTeam!.players) {
        futures.add(
          _updatePlayerRanking(
            playerId: player.playerId,
            matchId: matchId,
            newDelta: delta,
            currentRanking: player.ranking,
          ),
        );
      }

      for (final player in match.awayTeam!.players) {
        futures.add(
          _updatePlayerRanking(
            playerId: player.playerId,
            matchId: matchId,
            newDelta: -delta,
            currentRanking: player.ranking,
          ),
        );
      }

      await Future.wait(futures);
    }

    return match;
  }

  Future<void> _updatePlayerRanking({
    required String playerId,
    required String matchId,
    required double newDelta,
    required double currentRanking,
  }) async {
    // 1. Update ranking history and get the difference
    final diff = await _rankingRepository.updateMatchRankingChange(
      playerId: playerId,
      matchId: matchId,
      newDelta: newDelta,
    );

    // 2. Update player score if there is a difference
    if (diff != 0) {
      await _playerRepository.updatePlayerRanking(
        playerId: playerId,
        newRanking: currentRanking + diff,
      );
    }
  }
}

final updateMatchScoreUseCaseProvider = Provider<UpdateMatchScoreUseCase>((
  ref,
) {
  return UpdateMatchScoreUseCase(
    ref.read(matchRepositoryProvider),
    ref.read(rankingRepositoryProvider),
    ref.read(playerRepositoryProvider),
    ref.read(getSquadUseCaseProvider),
  );
});
