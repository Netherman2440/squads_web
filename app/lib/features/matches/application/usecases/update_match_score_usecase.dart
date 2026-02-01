import 'package:app/core/app_config.dart';
import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/matches/application/dto/match_details_dto.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/domain/repositories/team_repository.dart';
import 'package:app/features/matches/matches_providers.dart';
import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/players/domain/repositories/ranking_repository.dart';
import 'package:app/features/players/domain/repositories/player_repository.dart';
import 'package:app/features/players/players_providers.dart';
import 'package:app/features/squads/application/get_squad_use_case.dart';

class UpdateMatchScoreUseCase {
  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;
  final RankingRepository _rankingRepository;
  final PlayerRepository _playerRepository;
  final GetSquadUseCase _getSquadUseCase;
  final GetMatchUseCase _getMatchUseCase;
  final AuthEntity? _authEntity;

  UpdateMatchScoreUseCase(
    this._matchRepository,
    this._teamRepository,
    this._rankingRepository,
    this._playerRepository,
    this._getSquadUseCase,
    this._getMatchUseCase,
    this._authEntity,
  );

  Future<MatchDetailsDto> execute({
    required String matchId,
    required String squadId,
    required int homeScore,
    required int awayScore,
  }) async {
    if (_authEntity == null) {
      throw const UnauthorizedFailure('Not authenticated.');
    }

    // 1. Get Squad Settings
    final squad = await _getSquadUseCase.execute(squadId: squadId);

    // 2. Update Match Score
    await _matchRepository.updateMatchScore(
      matchId: matchId,
      homeScore: homeScore,
      awayScore: awayScore,
    );

    // 3. Update Rankings if enabled
    if (squad.rankingUpdate) {
      final delta = (homeScore - awayScore) * squad.rankingMultiplier;

      final teams = await _teamRepository.getMatchTeams(matchId);
      final homeTeam = teams.firstWhere(
        (t) => t.side.name == 'home',
        orElse: () => throw const ServerFailure('Home team missing'),
      );
      final awayTeam = teams.firstWhere(
        (t) => t.side.name == 'away',
        orElse: () => throw const ServerFailure('Away team missing'),
      );

      final futures = <Future>[];

      for (final player in homeTeam.players) {
        futures.add(
          _updatePlayerRanking(
            playerId: player.playerId,
            matchId: matchId,
            useExperienceFactor: squad.useExperienceFactor,
            newDelta: delta.toDouble(),
          ),
        );
      }

      for (final player in awayTeam.players) {
        futures.add(
          _updatePlayerRanking(
            playerId: player.playerId,
            matchId: matchId,
            useExperienceFactor: squad.useExperienceFactor,
            newDelta: -delta.toDouble(),
          ),
        );
      }

      await Future.wait(futures);
    }

    return _getMatchUseCase.execute(matchId: matchId);
  }

  Future<void> _updatePlayerRanking({
    required String playerId,
    required String matchId,
    required bool useExperienceFactor,
    required double newDelta,
  }) async {
    if (useExperienceFactor) {
      final history = await _rankingRepository.getPlayerRankingHistory(
        playerId,
      );
      final matchesPlayed = history
          .where((entry) => entry.matchId != null)
          .length
          .clamp(1, AppConfig.maxMatchesPlayed);

      newDelta /= matchesPlayed;
    }

    final entry = await _rankingRepository.getRankingHistoryEntryByMatch(
      matchId: matchId,
      playerId: playerId,
    );
    if (entry == null) {
      throw const ServerFailure('Ranking history entry not found.');
    }

    final oldDelta = entry.change ?? 0.0;
    final current = await _playerRepository.getPlayer(playerId: playerId);
    final desiredDiff = newDelta - oldDelta;
    if (desiredDiff == 0) return;

    final desiredRanking = current.ranking + desiredDiff;
    final clampedRanking = desiredRanking.clamp(0.0, 100.0).toDouble();
    final adjustedDiff = clampedRanking - current.ranking;
    final adjustedNewDelta = oldDelta + adjustedDiff;

    if (adjustedNewDelta != oldDelta) {
      await _rankingRepository.updateMatchRankingChange(
        playerId: playerId,
        matchId: matchId,
        newDelta: adjustedNewDelta,
      );
    }

    if (adjustedDiff != 0) {
      await _playerRepository.updatePlayerRanking(
        playerId: playerId,
        newRanking: clampedRanking,
      );
    }
  }
}

final updateMatchScoreUseCaseProvider = Provider<UpdateMatchScoreUseCase>((
  ref,
) {
  final authEntity = ref.watch(authStateProvider).value;
  return UpdateMatchScoreUseCase(
    ref.read(matchRepositoryProvider),
    ref.read(teamRepositoryProvider),
    ref.read(rankingRepositoryProvider),
    ref.read(playerRepositoryProvider),
    ref.read(getSquadUseCaseProvider),
    ref.read(getMatchUseCaseProvider),
    authEntity,
  );
});
