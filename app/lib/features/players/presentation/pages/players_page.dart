import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/presentation/controllers/players_notifier.dart';
import 'package:app/features/players/presentation/widgets/create_player_dialog.dart';
import 'package:app/features/players/presentation/widgets/empty_players_state.dart';
import 'package:app/features/players/presentation/widgets/players_list_widget.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';

class PlayersPage extends ConsumerStatefulWidget {
  const PlayersPage({super.key, required this.squadId});

  final String squadId;

  @override
  ConsumerState<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends ConsumerState<PlayersPage> {
  List<Player>? players;
  String _searchQuery = '';
  _PlayerSortOption _sortOption = _PlayerSortOption.scoreDesc;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(playersNotifierProvider.notifier)
          .loadPlayers(squadId: widget.squadId),
    );
  }

  Future<void> _showCreatePlayerDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => CreatePlayerDialog(squadId: widget.squadId),
    );
  }

  Widget _buildBody(AsyncValue<List<Player>> state) {
    return state.when(
      data: (players) {
        this.players = players;
        if (players.isEmpty) {
          return _buildEmptyState();
        }

        final visiblePlayers = _applySearchAndSort(players);
        return Column(
          children: [
            _buildSearchAndSortControls(),
            Expanded(child: _buildPlayersList(visiblePlayers)),
          ],
        );
      },
      error: (error, stackTrace) =>
          //show snackbar
          _buildErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playersNotifierProvider);
    final squadAsync = ref.watch(squadDetailProvider(widget.squadId));
    final role = squadAsync.maybeWhen(
      data: (squad) => squad.role,
      orElse: () => SquadRole.none,
    );
    final canAdd = role == SquadRole.owner || role == SquadRole.admin;

    ref.listen<AsyncValue<List<Player>>>(playersNotifierProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(error: (error, _) => _showFailureSnackBar(error));
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      body: _buildBody(state),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _showCreatePlayerDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
            )
          : null,
    );
  }

  void _showFailureSnackBar(Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = error is Failure ? error.message : error.toString();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
    });
  }

  Widget _buildPlayersList(List<Player> players) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(playersNotifierProvider.notifier)
          .refreshPlayers(squadId: widget.squadId),
      child: PlayersListWidget(players: players, squadId: widget.squadId),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(playersNotifierProvider.notifier)
          .refreshPlayers(squadId: widget.squadId),
      child: const EmptyPlayersState(),
    );
  }

  Widget _buildErrorState() {
    final cachedPlayers = players ?? [];
    if (cachedPlayers.isEmpty) {
      return _buildEmptyState();
    }
    final visiblePlayers = _applySearchAndSort(cachedPlayers);
    return Column(
      children: [
        _buildSearchAndSortControls(),
        Expanded(child: _buildPlayersList(visiblePlayers)),
      ],
    );
  }

  Widget _buildSearchAndSortControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final searchField = TextField(
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
            textCapitalization: TextCapitalization.none,
            onChanged: (value) => setState(() => _searchQuery = value),
          );

          final sortDropdown = DropdownButtonFormField<_PlayerSortOption>(
            initialValue: _sortOption,
            decoration: const InputDecoration(
              labelText: 'Sort',
              prefixIcon: Icon(Icons.sort),
            ),
            items: _PlayerSortOption.values
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(_sortLabel(option)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sortOption = value);
            },
          );

          if (isNarrow) {
            return Column(
              children: [searchField, const SizedBox(height: 12), sortDropdown],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              SizedBox(width: 240, child: sortDropdown),
            ],
          );
        },
      ),
    );
  }

  List<Player> _applySearchAndSort(List<Player> players) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? players
        : players
              .where((player) => player.name.toLowerCase().contains(query))
              .toList(growable: false);

    final sorted = [...filtered];
    switch (_sortOption) {
      case _PlayerSortOption.scoreDesc:
        sorted.sort((a, b) => b.ranking.compareTo(a.ranking));
        break;
      case _PlayerSortOption.scoreAsc:
        sorted.sort((a, b) => a.ranking.compareTo(b.ranking));
        break;
      case _PlayerSortOption.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case _PlayerSortOption.nameDesc:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
    }
    return sorted;
  }

  String _sortLabel(_PlayerSortOption option) {
    switch (option) {
      case _PlayerSortOption.scoreDesc:
        return 'Score: High to low';
      case _PlayerSortOption.scoreAsc:
        return 'Score: Low to high';
      case _PlayerSortOption.nameAsc:
        return 'Name: A to Z';
      case _PlayerSortOption.nameDesc:
        return 'Name: Z to A';
    }
  }
}

enum _PlayerSortOption { scoreDesc, scoreAsc, nameAsc, nameDesc }
