import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              SelectableText.rich(
                TextSpan(
                  text: 'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref
                    .read(playersNotifierProvider.notifier)
                    .loadPlayers(squadId: widget.squadId),
                child: const Text('Retry'),
              ),
            ],
          ),
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
}


