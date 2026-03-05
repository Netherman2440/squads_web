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
  late final TextEditingController _searchController;
  String _searchQuery = '';
  _PlayerSortOption _sortOption = _PlayerSortOption.scoreDesc;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(
      () => ref
          .read(playersNotifierProvider.notifier)
          .loadPlayers(squadId: widget.squadId),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            _SearchControls(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
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
      appBar: AppBar(
        title: const Text('Gracze'),
        actions: [
          PopupMenuButton<_PlayerSortOption>(
            tooltip: 'Sortuj',
            icon: const Icon(Icons.filter_alt),
            initialValue: _sortOption,
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => _PlayerSortOption.values
                .map(
                  (option) => PopupMenuItem<_PlayerSortOption>(
                    value: option,
                    child: Text(_sortLabel(option)),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _showCreatePlayerDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Dodaj gracza'),
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
        _SearchControls(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
        Expanded(child: _buildPlayersList(visiblePlayers)),
      ],
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
        return 'Ranking: malejąco';
      case _PlayerSortOption.scoreAsc:
        return 'Ranking: rosnąco';
      case _PlayerSortOption.nameAsc:
        return 'Nazwa: A-Z';
      case _PlayerSortOption.nameDesc:
        return 'Nazwa: Z-A';
    }
  }
}

enum _PlayerSortOption { scoreDesc, scoreAsc, nameAsc, nameDesc }

class _SearchControls extends StatelessWidget {
  const _SearchControls({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Szukaj',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
        ),
        textCapitalization: TextCapitalization.none,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onChanged,
      ),
    );
  }
}
