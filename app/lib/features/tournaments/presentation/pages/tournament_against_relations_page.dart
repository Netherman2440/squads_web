import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/presentation/widgets/draft_relation_widgets.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/tournaments/presentation/state/tournament_draft_helpers.dart';

class TournamentAgainstRelationsPage extends ConsumerStatefulWidget {
  const TournamentAgainstRelationsPage({
    super.key,
    required this.squadId,
    required this.tournamentId,
    required this.selectedPlayerIds,
    required this.teamCount,
    required this.initialDraftRules,
  });

  final String squadId;
  final String tournamentId;
  final List<String> selectedPlayerIds;
  final int teamCount;
  final List<DraftRule> initialDraftRules;

  @override
  ConsumerState<TournamentAgainstRelationsPage> createState() =>
      _TournamentAgainstRelationsPageState();
}

class _TournamentAgainstRelationsPageState
    extends ConsumerState<TournamentAgainstRelationsPage> {
  bool _isLoading = true;
  String? _error;
  List<Player> _selectedPlayers = const [];
  late List<List<String>> _togetherGroups;
  late List<List<String>> _againstGroups;

  @override
  void initState() {
    super.initState();

    _togetherGroups = togetherGroupsFromRules(widget.initialDraftRules);
    _againstGroups = againstGroupsFromRules(widget.initialDraftRules);

    Future.microtask(_loadPlayers);
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final players = await ref
          .read(getSquadPlayersUseCaseProvider)
          .execute(squadId: widget.squadId);

      final selectedIds = widget.selectedPlayerIds.toSet();
      final selected = players
          .where((player) => selectedIds.contains(player.playerId))
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPlayers = selected;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final validationMessage = validateDraftGroups(
      selectedPlayerIds: widget.selectedPlayerIds.toSet(),
      teamCount: widget.teamCount,
      togetherGroups: _togetherGroups,
      againstGroups: _againstGroups,
    );

    final togetherGroupByPlayer = buildTogetherGroupByPlayer(_togetherGroups);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relations: Against'),
        actions: [
          TextButton(
            onPressed: validationMessage == null ? _goGenerate : null,
            child: const Text('Generate'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: SelectableText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick players that must be placed in different teams.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (validationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SelectableText(
                        validationMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(
                    child: DraftRelationGroupsList(
                      title: 'Against rules',
                      emptyText: 'No against rules yet.',
                      groups: _againstGroups,
                      playersById: {
                        for (final player in _selectedPlayers)
                          player.playerId: player,
                      },
                      borderColor: Colors.red,
                      onAdd: _selectedPlayers.length < widget.teamCount
                          ? null
                          : () async {
                              final result = await showDraftRuleEditorDialog(
                                context: context,
                                title: 'Add against rule',
                                players: _selectedPlayers,
                                blockedPlayerIds: const <String>{},
                                minSelection: widget.teamCount,
                                exactSelection: widget.teamCount,
                                blockTogetherConflicts: true,
                                togetherGroupByPlayer: togetherGroupByPlayer,
                              );

                              if (result == null) {
                                return;
                              }

                              setState(() {
                                _againstGroups = [..._againstGroups, result];
                              });
                            },
                      onEdit: (index) async {
                        final result = await showDraftRuleEditorDialog(
                          context: context,
                          title: 'Edit against rule',
                          players: _selectedPlayers,
                          blockedPlayerIds: const <String>{},
                          minSelection: widget.teamCount,
                          exactSelection: widget.teamCount,
                          initialSelection: _againstGroups[index],
                          blockTogetherConflicts: true,
                          togetherGroupByPlayer: togetherGroupByPlayer,
                        );

                        if (result == null) {
                          return;
                        }

                        setState(() {
                          final next = [..._againstGroups];
                          next[index] = result;
                          _againstGroups = next;
                        });
                      },
                      onDelete: (index) {
                        setState(() {
                          final next = [..._againstGroups]..removeAt(index);
                          _againstGroups = next;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _goGenerate() {
    final rules = composeRules(
      togetherGroups: _togetherGroups,
      againstGroups: _againstGroups,
    );

    context.pushNamed(
      AppRoute.tournamentDraft.name,
      pathParameters: {
        'squadId': widget.squadId,
        'tournamentId': widget.tournamentId,
      },
      extra: {
        'selectedIds': widget.selectedPlayerIds,
        'teamCount': widget.teamCount,
        'draftRules': encodeDraftRules(rules),
      },
    );
  }
}
