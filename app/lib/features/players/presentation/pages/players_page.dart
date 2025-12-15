import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/presentation/controllers/players_notifier.dart';
import 'package:app/features/players/presentation/widgets/create_player_dialog.dart';
import 'package:app/features/players/presentation/widgets/empty_players_state.dart';
import 'package:app/features/players/presentation/widgets/players_list_widget.dart';

class PlayersPage extends ConsumerStatefulWidget {
  const PlayersPage({
    super.key,
    required this.squadId,
  });

  final String squadId;

  @override
  ConsumerState<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends ConsumerState<PlayersPage> {
  List<Player>? players;
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
      builder: (context) => CreatePlayerDialog(
        squadId: widget.squadId,
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Player>> state) {
    return state.when(
      data: (players) {
        this.players = players;
        if (players.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref
                .read(playersNotifierProvider.notifier)
                .refreshPlayers(squadId: widget.squadId),
            child: const EmptyPlayersState(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref
              .read(playersNotifierProvider.notifier)
              .refreshPlayers(squadId: widget.squadId),
          child: PlayersListWidget(
            players: players,
            squadId: widget.squadId,
          ),
        );
      },
      error: (error, stackTrace) => 
      //show snackbar
       RefreshIndicator(
          onRefresh: () => ref
              .read(playersNotifierProvider.notifier)
              .refreshPlayers(squadId: widget.squadId),
          child: PlayersListWidget(
            players: players ?? [],
            squadId: widget.squadId,
          ),
        ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playersNotifierProvider);
    ref.listen<AsyncValue<List<Player>>>(playersNotifierProvider, (previous, next) {
      next.whenOrNull(error: (error, _) => _showFailureSnackBar(error));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlayerDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Player'),
      ),
    );
  }

  void _showFailureSnackBar(Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = error is Failure ? error.message : error.toString();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
    });
  }
}


