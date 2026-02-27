import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/players/application/usecases/get_squad_players_usecase.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/tournaments/application/usecases/create_tournament_usecase.dart';

class CreateTournamentPage extends ConsumerStatefulWidget {
  const CreateTournamentPage({super.key, required this.squadId});

  final String squadId;

  @override
  ConsumerState<CreateTournamentPage> createState() =>
      _CreateTournamentPageState();
}

class _CreateTournamentPageState extends ConsumerState<CreateTournamentPage> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  List<Player> _players = const [];
  final Set<String> _selectedIds = <String>{};
  int _teamCount = 2;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPlayers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
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

      if (!mounted) {
        return;
      }

      setState(() {
        _players = players;
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

  Future<void> _createAndContinue() async {
    if (_selectedIds.length < _teamCount) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final tournament = await ref
          .read(createTournamentUseCaseProvider)
          .execute(
            squadId: widget.squadId,
            playerIds: _selectedIds.toList(growable: false),
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      context.pushNamed(
        AppRoute.tournamentDraftRelations.name,
        pathParameters: {
          'squadId': widget.squadId,
          'tournamentId': tournament.tournamentId,
        },
        extra: {
          'selectedIds': _selectedIds.toList(growable: false),
          'teamCount': _teamCount,
          'draftRules': _encodeDraftRules(const []),
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
          _isSubmitting = false;
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

    final searchValue = _searchController.text.trim().toLowerCase();
    final visiblePlayers = _players
        .where((player) => player.name.toLowerCase().contains(searchValue))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Tournament')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tournament name (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Teams:'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _teamCount,
                        items: const [2, 3, 4]
                            .map(
                              (count) => DropdownMenuItem<int>(
                                value: count,
                                child: Text('$count'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _teamCount = value;
                          });
                        },
                      ),
                      const Spacer(),
                      Text('Selected: ${_selectedIds.length}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search players',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SelectableText(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(
                    child: visiblePlayers.isEmpty
                        ? const Center(child: Text('No players found.'))
                        : ListView.builder(
                            itemCount: visiblePlayers.length,
                            itemBuilder: (context, index) {
                              final player = visiblePlayers[index];
                              final selected = _selectedIds.contains(
                                player.playerId,
                              );

                              return CheckboxListTile(
                                value: selected,
                                title: Text(player.name),
                                subtitle: Text(
                                  'Ranking: ${player.ranking.toStringAsFixed(1)}',
                                ),
                                onChanged: !canManage
                                    ? null
                                    : (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedIds.add(player.playerId);
                                          } else {
                                            _selectedIds.remove(
                                              player.playerId,
                                            );
                                          }
                                        });
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed:
              canManage && _selectedIds.length >= _teamCount && !_isSubmitting
              ? _createAndContinue
              : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue to relations'),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _encodeDraftRules(List<DraftRule> rules) {
  return [
    for (final rule in rules)
      {'type': rule.type.name, 'playerIds': rule.playerIds},
  ];
}
