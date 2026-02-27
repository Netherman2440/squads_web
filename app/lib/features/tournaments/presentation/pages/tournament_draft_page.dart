import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/application/create_draft_use_case.dart';
import 'package:app/features/draft/application/get_player_pair_win_rates_use_case.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/domain/entities/head_to_head_win_rate.dart';
import 'package:app/features/draft/domain/services/draft_algorithm_policy.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/application/usecases/accept_tournament_draft_usecase.dart';
import 'package:app/features/tournaments/application/usecases/get_tournament_draft_usecase.dart';
import 'package:app/features/tournaments/application/usecases/save_tournament_draft_usecase.dart';
import 'package:app/features/tournaments/domain/entities/tournament_draft.dart';
import 'package:app/features/tournaments/presentation/state/tournament_providers.dart';

class TournamentDraftPage extends ConsumerStatefulWidget {
  const TournamentDraftPage({
    super.key,
    required this.squadId,
    required this.tournamentId,
    this.selectedPlayerIds = const [],
    this.teamCount = 2,
    this.draftRules = const [],
    this.tournamentDraftId,
  });

  final String squadId;
  final String tournamentId;
  final List<String> selectedPlayerIds;
  final int teamCount;
  final List<DraftRule> draftRules;
  final String? tournamentDraftId;

  @override
  ConsumerState<TournamentDraftPage> createState() =>
      _TournamentDraftPageState();
}

class _TournamentDraftPageState extends ConsumerState<TournamentDraftPage> {
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _error;
  String? _draftId;
  int _selectedIndex = 0;
  List<Draft> _proposals = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedIndex = 0;
    });

    try {
      if (widget.tournamentDraftId != null &&
          widget.tournamentDraftId!.isNotEmpty) {
        await _loadStoredDraft(widget.tournamentDraftId!);
      } else {
        await _generateDraft();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error is Failure ? error.message : error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStoredDraft(String draftId) async {
    final draft = await ref
        .read(getTournamentDraftUseCaseProvider)
        .execute(tournamentDraftId: draftId);

    if (draft == null) {
      throw const NotFoundFailure('Tournament draft not found.');
    }

    _draftId = draft.tournamentDraftId;

    if (draft.status == 'error') {
      throw ValidationFailure(draft.errorMessage ?? 'Draft failed previously.');
    }

    final players = await ref
        .read(getSquadPlayersUseCaseProvider)
        .execute(squadId: widget.squadId);

    final playersById = {for (final player in players) player.playerId: player};
    final proposals = _restoreDraftsFromPayload(
      proposals: draft.proposals,
      playersById: playersById,
    );

    setState(() {
      _proposals = proposals;
      _selectedIndex = 0;
    });
  }

  Future<void> _generateDraft() async {
    final selectedIds = widget.selectedPlayerIds.toSet().toList(
      growable: false,
    );
    if (selectedIds.length < widget.teamCount) {
      throw ValidationFailure(
        'Draft requires at least ${widget.teamCount} selected players.',
      );
    }

    final players = await ref
        .read(getSquadPlayersUseCaseProvider)
        .execute(squadId: widget.squadId);

    final selectedPlayers = players
        .where((player) => selectedIds.contains(player.playerId))
        .toList(growable: false);

    final algorithm = DraftAlgorithmPolicy.resolve(
      teamCount: widget.teamCount,
      playerCount: selectedPlayers.length,
    );

    final createDraftUseCase = switch (algorithm) {
      DraftAlgorithmSelection.combinatory => ref.read(
        combinatoryCreateDraftUseCaseProvider,
      ),
      DraftAlgorithmSelection.greedy => ref.read(
        greedyCreateDraftUseCaseProvider,
      ),
    };

    final seed = algorithm == DraftAlgorithmSelection.greedy
        ? Random().nextInt(0x7FFFFFFF)
        : null;

    final proposals = await createDraftUseCase.execute(
      players: selectedPlayers,
      teamCount: widget.teamCount,
      rules: widget.draftRules,
      seed: seed,
    );

    final winRates = await ref
        .read(getPlayerPairWinRatesUseCaseProvider)
        .execute(playerIds: selectedIds);

    final winRateMatrix = _buildWinRateMatrix(winRates);

    final draftId = await ref
        .read(saveTournamentDraftUseCaseProvider)
        .executeCompleted(
          squadId: widget.squadId,
          tournamentId: widget.tournamentId,
          selectedPlayerIds: selectedIds,
          teamCount: widget.teamCount,
          rules: widget.draftRules,
          proposals: proposals,
          winRateMatrix: winRateMatrix,
          seed: seed,
        );

    setState(() {
      _draftId = draftId;
      _proposals = proposals;
      _selectedIndex = 0;
    });
  }

  Future<void> _acceptProposal() async {
    final draftId = _draftId;
    if (draftId == null) {
      return;
    }

    setState(() {
      _isAccepting = true;
      _error = null;
    });

    try {
      await ref
          .read(acceptTournamentDraftUseCaseProvider)
          .execute(
            tournamentId: widget.tournamentId,
            tournamentDraftId: draftId,
            proposalIndex: _selectedIndex,
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(tournamentDetailsProvider(widget.tournamentId));
      ref.invalidate(squadTournamentsProvider(widget.squadId));

      context.goNamed(
        AppRoute.tournamentDetails.name,
        pathParameters: {
          'squadId': widget.squadId,
          'tournamentId': widget.tournamentId,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is Failure ? error.message : error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadAsync = ref.watch(squadDetailProvider(widget.squadId));
    final canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Draft')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (widget.tournamentDraftId == null)
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            )
          : _proposals.isEmpty
          ? const Center(child: Text('No draft proposals generated.'))
          : Column(
              children: [
                const SizedBox(height: 12),
                _ProposalNavigator(
                  index: _selectedIndex,
                  total: _proposals.length,
                  onPrev: _selectedIndex > 0
                      ? () {
                          setState(() {
                            _selectedIndex -= 1;
                          });
                        }
                      : null,
                  onNext: _selectedIndex < _proposals.length - 1
                      ? () {
                          setState(() {
                            _selectedIndex += 1;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ProposalTeamsView(
                    proposal: _proposals[_selectedIndex],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !_isLoading && _error == null
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.goNamed(
                          AppRoute.tournamentDetails.name,
                          pathParameters: {
                            'squadId': widget.squadId,
                            'tournamentId': widget.tournamentId,
                          },
                        );
                      },
                      child: const Text('Tournament'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canManage && !_isAccepting
                          ? _acceptProposal
                          : null,
                      child: _isAccepting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept Proposal'),
                    ),
                  ),
                ],
              ),
            )
          : null,
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
        Text('Proposal ${index + 1} / $total'),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _ProposalTeamsView extends StatelessWidget {
  const _ProposalTeamsView({required this.proposal});

  final Draft proposal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final teamCards = [
          for (var i = 0; i < proposal.teams.length; i++)
            SizedBox(
              width: isCompact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2,
              child: _TeamProposalCard(team: proposal.teams[i], index: i),
            ),
        ];

        if (isCompact) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teamCards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => teamCards[index],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 12, runSpacing: 12, children: teamCards),
        );
      },
    );
  }
}

class _TeamProposalCard extends StatelessWidget {
  const _TeamProposalCard({required this.team, required this.index});

  final DraftTeam team;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Players: ${team.players.length}'),
            Text('Total ranking: ${team.totalRanking.toStringAsFixed(1)}'),
            const Divider(height: 20),
            for (final player in team.players)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${player.name} (${player.ranking.toStringAsFixed(1)})',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<Draft> _restoreDraftsFromPayload({
  required List<TournamentDraftProposal> proposals,
  required Map<String, Player> playersById,
}) {
  final drafts = <Draft>[];

  for (final proposal in proposals) {
    final teams = <DraftTeam>[];
    final usedPlayerIds = <String>{};

    for (var teamIndex = 0; teamIndex < proposal.teams.length; teamIndex++) {
      final teamPlayerIds = proposal.teams[teamIndex];
      final players = <Player>[];
      var totalRanking = 0.0;

      for (final playerId in teamPlayerIds) {
        if (!usedPlayerIds.add(playerId)) {
          continue;
        }

        final player = playersById[playerId];
        if (player == null) {
          continue;
        }

        players.add(player);
        totalRanking += player.ranking;
      }

      teams.add(
        DraftTeam(
          index: teamIndex,
          players: players,
          totalRanking: totalRanking,
        ),
      );
    }

    if (teams.isNotEmpty) {
      drafts.add(Draft(teams: teams));
    }
  }

  return drafts;
}

Map<String, Map<String, double>> _buildWinRateMatrix(
  List<HeadToHeadWinRate> winRates,
) {
  final matrix = <String, Map<String, double>>{};
  for (final rate in winRates) {
    final opponents = matrix.putIfAbsent(
      rate.playerId,
      () => <String, double>{},
    );
    opponents[rate.oppPlayerId] = rate.winRate;
  }
  return matrix;
}
