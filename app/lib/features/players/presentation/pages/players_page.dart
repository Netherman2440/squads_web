import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';

import '../controllers/players_notifier.dart';
import '../widgets/create_player_dialog.dart';
import '../widgets/empty_players_state.dart';
import '../widgets/players_error_view.dart';
import '../widgets/players_list_widget.dart';
import '../widgets/players_search_bar.dart';
import '../widgets/players_sort_menu.dart';

class PlayersPage extends ConsumerWidget {
  const PlayersPage({
    super.key,
    required this.squadId,
  });

  final String squadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadState = ref.watch(squadDetailProvider(squadId));
    final playersState = ref.watch(playersNotifierProvider(squadId));
    final notifier = ref.read(playersNotifierProvider(squadId).notifier);

    final squad = squadState.asData?.value;
    final role = squad?.role ?? UserSquadRole.none;
    final canManage = notifier.canManagePlayers(role);

    return Scaffold(
      appBar: AppBar(
        title: Text('${squad?.name ?? 'Squad'} players'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/squads/$squadId'),
        ),
        actions: [
          if (canManage)
            IconButton(
              onPressed: () => _openCreateDialog(context, notifier),
              icon: const Icon(Icons.person_add_alt),
              tooltip: 'Add player',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: playersState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => PlayersErrorView(
              error: error,
              onRetry: notifier.refreshPlayers,
            ),
            data: (data) {
              final players = data.filteredPlayers;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    squad: squad,
                    playersCount: players.length,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PlayersSearchBar(
                        initialValue: data.searchQuery,
                        onChanged: notifier.updateSearchQuery,
                      ),
                      PlayersSortMenu(
                        selected: data.sortOption,
                        onChanged: notifier.updateSortOption,
                      ),
                      if (canManage)
                        FilledButton.icon(
                          onPressed: () => _openCreateDialog(context, notifier),
                          icon: const Icon(Icons.add),
                          label: const Text('Add player'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: notifier.refreshPlayers,
                      child: players.isEmpty
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: [
                                EmptyPlayersState(
                                  canAdd: canManage,
                                  onAdd: canManage
                                      ? () => _openCreateDialog(
                                            context,
                                            notifier,
                                          )
                                      : null,
                                ),
                              ],
                            )
                          : PlayersListWidget(
                              players: players,
                              canManage: canManage,
                              onDelete: notifier.deletePlayer,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDialog(
    BuildContext context,
    PlayersNotifier notifier,
  ) async {
    final result = await showDialog<CreatePlayerResult?>(
      context: context,
      builder: (context) => const CreatePlayerDialog(),
    );

    if (result != null) {
      await notifier.addPlayer(
        name: result.name,
        position: result.position,
        baseScore: result.baseScore,
      );
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.squad,
    required this.playersCount,
  });

  final Squad? squad;
  final int playersCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                squad?.name ?? 'Players',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Total players: $playersCount',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
