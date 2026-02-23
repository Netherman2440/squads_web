import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:app/core/app_config.dart';
import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/core/utils/team_ranking.dart';
import 'package:app/core/widgets/probability_slider.dart';
import 'package:app/features/draft/application/get_match_draft_use_case.dart';
import 'package:app/features/draft/application/save_match_draft_use_case.dart';
import 'package:app/features/draft/presentation/controllers/draft_session_notifier.dart';
import 'package:app/features/draft/presentation/widgets/draft_draggable_player_tile.dart';
import 'package:app/features/matches/application/dto/match_details_dto.dart';
import 'package:app/features/matches/application/usecases/get_match_usecase.dart';
import 'package:app/features/matches/presentation/controllers/create_match_controller.dart';
import 'package:app/features/matches/presentation/controllers/match_details_notifier.dart';
import 'package:app/features/matches/presentation/controllers/squad_matches_notifier.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/players_providers.dart';

final _logger = Logger('DraftResultsPage');

class DraftResultsPage extends ConsumerStatefulWidget {
  const DraftResultsPage({
    super.key,
    required this.squadId,
    required this.selectedPlayerIds,
    this.matchId,
    this.playWithSubstitute = true,
  });

  final String squadId;
  final List<String> selectedPlayerIds;
  final String? matchId;
  final bool playWithSubstitute;

  @override
  ConsumerState<DraftResultsPage> createState() => _DraftResultsPageState();
}

class _DraftResultsPageState extends ConsumerState<DraftResultsPage> {
  bool _playWithSubstitute = true;
  int? _loadingPlayerCount;
  _DraftLoadingMode _loadingMode = _DraftLoadingMode.generating;

  String? get _loadMatchId {
    final value = widget.matchId;
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _playWithSubstitute = widget.playWithSubstitute;
    _loadingPlayerCount = widget.selectedPlayerIds.length;
    _loadingMode = widget.selectedPlayerIds.length >= 2
        ? _DraftLoadingMode.generating
        : _DraftLoadingMode.checkingExisting;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(draftSessionNotifierProvider.notifier)
          .load(
            squadId: widget.squadId,
            selectedPlayerIds: widget.selectedPlayerIds,
            algorithm: _preferredAlgorithm,
            matchId: _loadMatchId,
            playWithSubstitute: _playWithSubstitute,
          ),
    );
    Future.microtask(_resolveLoadingModeAndCount);
  }

  @override
  void didUpdateWidget(covariant DraftResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playWithSubstitute != widget.playWithSubstitute) {
      _playWithSubstitute = widget.playWithSubstitute;
    }
    if (oldWidget.matchId != widget.matchId ||
        oldWidget.selectedPlayerIds != widget.selectedPlayerIds) {
      _loadingPlayerCount = widget.selectedPlayerIds.length;
      _loadingMode = widget.selectedPlayerIds.length >= 2
          ? _DraftLoadingMode.generating
          : _DraftLoadingMode.checkingExisting;
      Future.microtask(_resolveLoadingModeAndCount);
    }
  }

  Future<void> _resolveLoadingModeAndCount() async {
    final matchId = _loadMatchId;
    if (widget.selectedPlayerIds.length >= 2 || matchId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMode = _DraftLoadingMode.generating;
      });
      return;
    }

    try {
      final storedDraft = await ref
          .read(getMatchDraftUseCaseProvider)
          .execute(matchId: matchId);
      if (!mounted) {
        return;
      }

      if (storedDraft != null) {
        setState(() {
          _loadingMode = _DraftLoadingMode.checkingExisting;
        });
        return;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMode = _DraftLoadingMode.checkingExisting;
      });
      return;
    }

    await _hydrateLoadingPlayerCount();
  }

  DraftAlgorithm get _preferredAlgorithm {
    final selectedCount = widget.selectedPlayerIds.toSet().length;
    if (selectedCount >= AppConfig.greedyDraftThresholdPlayers) {
      return DraftAlgorithm.greedy;
    }
    return DraftAlgorithm.combinatory;
  }

  Future<void> _hydrateLoadingPlayerCount() async {
    final matchId = _loadMatchId;
    if (matchId == null || widget.selectedPlayerIds.length >= 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMode = _DraftLoadingMode.generating;
      });
      return;
    }

    try {
      final rankingEntries = await ref
          .read(rankingRepositoryProvider)
          .getMatchRankingHistory(matchId);
      var count = rankingEntries.map((entry) => entry.playerId).toSet().length;

      if (count < 2) {
        final match = await ref
            .read(getMatchUseCaseProvider)
            .execute(matchId: matchId);
        count = <String>{
          for (final player in match.homeTeam?.players ?? const [])
            player.playerId,
          for (final player in match.awayTeam?.players ?? const [])
            player.playerId,
        }.length;
      }

      if (!mounted) {
        return;
      }

      if (count > 0) {
        setState(() {
          _loadingPlayerCount = count;
          _loadingMode = count >= 2
              ? _DraftLoadingMode.generating
              : _DraftLoadingMode.checkingExisting;
        });
      }
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to hydrate loading player count for matchId=$matchId',
        error,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftSessionNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: _loadMatchId == null,
        leading: _loadMatchId == null
            ? null
            : IconButton(
                tooltip: 'Wróć do meczu',
                onPressed: () {
                  context.goNamed(
                    AppRoute.matchDetails.name,
                    pathParameters: {
                      'squadId': widget.squadId,
                      'matchId': _loadMatchId!,
                    },
                  );
                },
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Text('Draft'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CreateMatchButton(
              squadId: widget.squadId,
              matchId: widget.matchId,
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => _DraftLoadingBody(
          selectedPlayerCount:
              _loadingPlayerCount ?? widget.selectedPlayerIds.length,
          showCombinationCount: _loadingMode == _DraftLoadingMode.generating,
        ),
        error: (error, _) => _ErrorBody(
          error: error,
          squadId: widget.squadId,
          matchId: _loadMatchId,
          selectedPlayerIds: widget.selectedPlayerIds,
        ),
        data: (data) {
          if (data.proposals.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No draft proposals. Go back and select players.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProposalNavigator(
                  index: data.selectedIndex,
                  total: data.proposals.length,
                  onPrev: data.selectedIndex == 0
                      ? null
                      : () => ref
                            .read(draftSessionNotifierProvider.notifier)
                            .selectProposal(data.selectedIndex - 1),
                  onNext: data.selectedIndex == data.proposals.length - 1
                      ? null
                      : () => ref
                            .read(draftSessionNotifierProvider.notifier)
                            .selectProposal(data.selectedIndex + 1),
                ),
                const SizedBox(height: 12),
                _TotalsRow(
                  homePlayers: data.home,
                  awayPlayers: data.away,
                  playWithSubstitute: _playWithSubstitute,
                  homeWinProbability: data.homeWinProbability,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact =
                          constraints.maxWidth < AppConfig.compactWidth;
                      final gap = isCompact ? 8.0 : 12.0;
                      final panelWidth = math.max(
                        220.0,
                        (constraints.maxWidth - gap) / 2,
                      );
                      final homePanel = isCompact
                          ? SizedBox(
                              width: panelWidth,
                              child: _RosterPanel(
                                title: 'Home',
                                players: data.home,
                                compact: isCompact,
                                onAcceptPlayerId: (playerId) => ref
                                    .read(draftSessionNotifierProvider.notifier)
                                    .movePlayer(
                                      playerId: playerId,
                                      toHome: true,
                                    ),
                              ),
                            )
                          : Expanded(
                              child: _RosterPanel(
                                title: 'Home',
                                players: data.home,
                                compact: isCompact,
                                onAcceptPlayerId: (playerId) => ref
                                    .read(draftSessionNotifierProvider.notifier)
                                    .movePlayer(
                                      playerId: playerId,
                                      toHome: true,
                                    ),
                              ),
                            );

                      final awayPanel = isCompact
                          ? SizedBox(
                              width: panelWidth,
                              child: _RosterPanel(
                                title: 'Away',
                                players: data.away,
                                compact: isCompact,
                                onAcceptPlayerId: (playerId) => ref
                                    .read(draftSessionNotifierProvider.notifier)
                                    .movePlayer(
                                      playerId: playerId,
                                      toHome: false,
                                    ),
                              ),
                            )
                          : Expanded(
                              child: _RosterPanel(
                                title: 'Away',
                                players: data.away,
                                compact: isCompact,
                                onAcceptPlayerId: (playerId) => ref
                                    .read(draftSessionNotifierProvider.notifier)
                                    .movePlayer(
                                      playerId: playerId,
                                      toHome: false,
                                    ),
                              ),
                            );

                      final content = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          homePanel,
                          SizedBox(width: gap),
                          awayPanel,
                        ],
                      );
                      if (isCompact) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: content,
                          ),
                        );
                      }
                      return content;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DraftLoadingBody extends StatelessWidget {
  const _DraftLoadingBody({
    required this.selectedPlayerCount,
    required this.showCombinationCount,
  });

  final int selectedPlayerCount;
  final bool showCombinationCount;

  @override
  Widget build(BuildContext context) {
    final usesGreedyHeuristic =
        selectedPlayerCount >= AppConfig.greedyDraftThresholdPlayers;
    final count = usesGreedyHeuristic
        ? BigInt.from(AppConfig.greedyDraftVariantChecks)
        : _estimatedCheckedDraftCount(
            playerCount: selectedPlayerCount,
            teamCount: 2,
          );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Trwa generowanie draftu. To może chwilę potrwać.'),
          const SizedBox(height: 8),
          Text(
            showCombinationCount
                ? (count == null
                      ? 'Sprawdzane warianty: wyliczanie...'
                      : 'Sprawdzane warianty: ${_formatBigInt(count)}')
                : 'Sprawdzam zapisany draft...',
          ),
          if (showCombinationCount) ...[
            const SizedBox(height: 6),
            const Text(
              'Możesz wyjść z tego ekranu, ale nie zamykaj przeglądarki.',
            ),
            if (usesGreedyHeuristic) ...[
              const SizedBox(height: 6),
              const Text(
                'Uwaga: przy większej liczbie graczy wynik draftu '
                'może być mniej dokładny.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

enum _DraftLoadingMode { checkingExisting, generating }

class _CreateMatchButton extends ConsumerWidget {
  const _CreateMatchButton({required this.squadId, this.matchId});

  final String squadId;
  final String? matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftState = ref.watch(draftSessionNotifierProvider);
    final createMatchState = ref.watch(createMatchControllerProvider);
    final draftData = draftState.asData?.value;

    final isExistingMatch = matchId != null && matchId!.isNotEmpty;
    final hasProposals = draftData != null && draftData.proposals.isNotEmpty;

    final isLoading = createMatchState.isLoading;

    return IconButton(
      tooltip: isExistingMatch ? 'Update Match' : 'Create Match',
      onPressed: isLoading || !hasProposals
          ? null
          : () async {
              MatchDetailsDto? match;
              if (isExistingMatch) {
                match = await ref
                    .read(createMatchControllerProvider.notifier)
                    .updateMatch(
                      matchId: matchId!,
                      homePlayers: draftData.home,
                      awayPlayers: draftData.away,
                    );
              } else {
                match = await ref
                    .read(createMatchControllerProvider.notifier)
                    .createMatch(
                      squadId: squadId,
                      homePlayers: draftData.home,
                      awayPlayers: draftData.away,
                      // Could prompt for team names/colors here if needed
                    );
              }

              final persistedMatchId = isExistingMatch
                  ? matchId
                  : match?.matchId;
              if (persistedMatchId != null) {
                try {
                  await ref
                      .read(saveMatchDraftUseCaseProvider)
                      .executeCompleted(
                        squadId: squadId,
                        matchId: persistedMatchId,
                        proposals: draftData.proposals,
                        winRateMatrix: draftData.winRateMatrix,
                        teamCount: draftData.proposals.first.teams.length,
                        seed: draftData.seed,
                      );
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Match saved, but draft payload failed to save: $error',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              }

              if (context.mounted && match != null) {
                if (isExistingMatch) {
                  ref.invalidate(matchDetailsProvider(matchId!));
                }
                ref.invalidate(squadMatchesProvider(squadId));
                context.goNamed(
                  AppRoute.matchDetails.name,
                  pathParameters: {
                    'squadId': squadId,
                    'matchId': match.matchId,
                  },
                );
              } else if (context.mounted && createMatchState.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to ${isExistingMatch ? 'update' : 'create'} match: ${createMatchState.error}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
      icon: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_circle_outline),
    );
  }
}

class _ProposalNavigator extends StatelessWidget {
  const _ProposalNavigator({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text('Draft ${index + 1} of $total'),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.homePlayers,
    required this.awayPlayers,
    required this.playWithSubstitute,
    required this.homeWinProbability,
  });

  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final bool playWithSubstitute;
  final double homeWinProbability;

  @override
  Widget build(BuildContext context) {
    final effectiveHome = _uiTeamScore(
      players: homePlayers,
      opponentCount: awayPlayers.length,
      playWithSubstitute: playWithSubstitute,
    );

    final effectiveAway = _uiTeamScore(
      players: awayPlayers,
      opponentCount: homePlayers.length,
      playWithSubstitute: playWithSubstitute,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final theme = Theme.of(context);
        final slider = ProbabilitySlider(
          title: 'Draft win probability',
          homeColor: theme.colorScheme.primary,
          awayColor: theme.colorScheme.secondary,
          homeProbability: homeWinProbability,
          infoText:
              'Calculated from head-to-head win rates between the '
              'selected players.',
        );

        if (isCompact) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TotalChip(label: 'Home ranking', value: effectiveHome),
                  _TotalChip(label: 'Away ranking', value: effectiveAway),
                ],
              ),
              const SizedBox(height: 12),
              slider,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: _TotalChip(label: 'Home ranking', value: effectiveHome),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(flex: 2, child: slider),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: _TotalChip(label: 'Away ranking', value: effectiveAway),
              ),
            ),
          ],
        );
      },
    );
  }
}

double _uiTeamScore({
  required List<Player> players,
  required int opponentCount,
  required bool playWithSubstitute,
}) {
  var total = 0.0;
  for (final player in players) {
    total += player.ranking;
  }

  return effectiveTeamRanking(
    totalRanking: total,
    teamSize: players.length,
    opponentTeamSize: opponentCount,
    playWithSubstitute: playWithSubstitute,
  );
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: ${value.toStringAsFixed(1)}'));
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({
    required this.title,
    required this.players,
    required this.compact,
    required this.onAcceptPlayerId,
  });

  final String title;
  final List<Player> players;
  final bool compact;
  final ValueChanged<String> onAcceptPlayerId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final playerId = _extractPlayerId(details.data);
        if (playerId == null) {
          return false;
        }

        return !players.any((p) => p.playerId == playerId);
      },
      onAcceptWithDetails: (details) {
        final playerId = _extractPlayerId(details.data);
        if (playerId == null) {
          return;
        }

        onAcceptPlayerId(playerId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Card(
          shape: isHighlighted
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: compact ? 14 : null,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Expanded(
                  child: players.isEmpty
                      ? const Center(child: Text('No players.'))
                      : Builder(
                          builder: (context) {
                            final sortedPlayers = [...players]
                              ..sort((a, b) => b.ranking.compareTo(a.ranking));
                            return ListView.builder(
                              itemCount: sortedPlayers.length,
                              itemBuilder: (context, index) {
                                final p = sortedPlayers[index];
                                return DraftDraggablePlayerTile(
                                  player: p,
                                  trailing: const Icon(Icons.drag_indicator),
                                  dragData: p.playerId,
                                  compact: compact,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.error,
    required this.squadId,
    required this.matchId,
    required this.selectedPlayerIds,
  });

  final Object error;
  final String squadId;
  final String? matchId;
  final List<String> selectedPlayerIds;

  @override
  Widget build(BuildContext context) {
    final err = error;
    final message = err is Failure ? err.message : err.toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText.rich(
            TextSpan(
              text: message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          if (matchId != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                context.pushNamed(
                  AppRoute.draftCreate.name,
                  pathParameters: {'squadId': squadId},
                  extra: {'selectedIds': selectedPlayerIds, 'matchId': matchId},
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Wybierz zawodników i spróbuj ponownie'),
            ),
          ],
        ],
      ),
    );
  }
}

BigInt? _estimatedCheckedDraftCount({
  required int playerCount,
  required int teamCount,
}) {
  if (playerCount < teamCount || playerCount <= 0 || teamCount <= 0) {
    return null;
  }

  final teamSizes = _calculateTeamSizes(
    playerCount: playerCount,
    teamCount: teamCount,
  );

  var remainingPlayers = playerCount;
  var count = BigInt.one;

  for (var i = 0; i < teamSizes.length - 1; i++) {
    final teamSize = teamSizes[i];
    count *= _binomial(remainingPlayers - 1, teamSize - 1);
    remainingPlayers -= teamSize;
  }

  return count;
}

List<int> _calculateTeamSizes({
  required int playerCount,
  required int teamCount,
}) {
  final base = playerCount ~/ teamCount;
  final remainder = playerCount % teamCount;

  return List<int>.generate(
    teamCount,
    (index) => base + (index < remainder ? 1 : 0),
  );
}

BigInt _binomial(int n, int k) {
  if (k < 0 || n < 0 || k > n) {
    return BigInt.zero;
  }

  var adjusted = k;
  if (adjusted > n - adjusted) {
    adjusted = n - adjusted;
  }

  var result = BigInt.one;
  for (var i = 1; i <= adjusted; i++) {
    result = (result * BigInt.from(n - adjusted + i)) ~/ BigInt.from(i);
  }

  return result;
}

String _formatBigInt(BigInt value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final isSeparator = i > 0 && (digits.length - i) % 3 == 0;
    if (isSeparator) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }

  return buffer.toString();
}

String? _extractPlayerId(Object data) {
  if (data is String && data.isNotEmpty) {
    return data;
  }
  return null;
}
