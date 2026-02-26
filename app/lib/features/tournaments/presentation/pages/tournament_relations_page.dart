import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/features/draft/presentation/widgets/draft_relation_widgets.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/tournaments/presentation/state/tournament_draft_helpers.dart';

class TournamentRelationsPage extends ConsumerStatefulWidget {
  const TournamentRelationsPage({
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
  final List<dynamic> initialDraftRules;

  @override
  ConsumerState<TournamentRelationsPage> createState() =>
      _TournamentRelationsPageState();
}

class _TournamentRelationsPageState
    extends ConsumerState<TournamentRelationsPage> {
  bool _isLoading = true;
  String? _error;
  List<Player> _selectedPlayers = const [];
  late List<List<String>> _togetherGroups;
  late List<List<String>> _againstGroups;

  @override
  void initState() {
    super.initState();

    final initialRules = decodeDraftRules(widget.initialDraftRules);
    _togetherGroups = togetherGroupsFromRules(initialRules);
    _againstGroups = againstGroupsFromRules(initialRules);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relations: Together'),
        actions: [
          TextButton(
            onPressed: validationMessage == null ? _goNext : null,
            child: const Text('Next'),
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
                    'Pick players that should stay together in one team.',
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
                      title: 'Together rules',
                      emptyText: 'No together rules yet.',
                      groups: _togetherGroups,
                      playersById: {
                        for (final player in _selectedPlayers)
                          player.playerId: player,
                      },
                      borderColor: Colors.green,
                      onAdd: _selectedPlayers.length < 2
                          ? null
                          : () async {
                              final blockedIds = <String>{
                                ..._togetherGroups.expand((group) => group),
                              };
                              final result = await showDraftRuleEditorDialog(
                                context: context,
                                title: 'Add together rule',
                                players: _selectedPlayers,
                                blockedPlayerIds: blockedIds,
                                minSelection: 2,
                              );
                              if (result == null) {
                                return;
                              }

                              setState(() {
                                _togetherGroups = [..._togetherGroups, result];
                              });
                            },
                      onEdit: (index) async {
                        final initialSelection = _togetherGroups[index];
                        final blockedIds = <String>{
                          for (var i = 0; i < _togetherGroups.length; i++)
                            if (i != index) ..._togetherGroups[i],
                        };

                        final result = await showDraftRuleEditorDialog(
                          context: context,
                          title: 'Edit together rule',
                          players: _selectedPlayers,
                          blockedPlayerIds: blockedIds,
                          minSelection: 2,
                          initialSelection: initialSelection,
                        );
                        if (result == null) {
                          return;
                        }

                        setState(() {
                          final next = [..._togetherGroups];
                          next[index] = result;
                          _togetherGroups = next;
                        });
                      },
                      onDelete: (index) {
                        setState(() {
                          final next = [..._togetherGroups]..removeAt(index);
                          _togetherGroups = next;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _goNext() {
    final rules = composeRules(
      togetherGroups: _togetherGroups,
      againstGroups: _againstGroups,
    );

    context.pushNamed(
      AppRoute.tournamentDraftAgainstRelations.name,
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
