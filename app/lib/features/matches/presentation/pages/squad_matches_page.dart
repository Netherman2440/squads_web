import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/matches/domain/entities/match.dart';
import 'package:app/features/matches/presentation/controllers/squad_matches_notifier.dart';
import 'package:app/features/matches/presentation/widgets/match_tile.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';

class SquadMatchesPage extends ConsumerStatefulWidget {
  const SquadMatchesPage({
    super.key,
    required this.squadId,
  });

  final String squadId;

  @override
  ConsumerState<SquadMatchesPage> createState() => _SquadMatchesPageState();
}

class _SquadMatchesPageState extends ConsumerState<SquadMatchesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(squadMatchesNotifierProvider.notifier).load(
            squadId: widget.squadId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchesState = ref.watch(squadMatchesNotifierProvider);
    final squadState = ref.watch(squadDetailProvider(widget.squadId));

    final canManage = squadState.maybeWhen(
      data: (squad) =>
          squad.role == SquadRole.owner || squad.role == SquadRole.admin,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          if (canManage)
            IconButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('Add match'),
                    content: SelectableText(
                      'Match creation flow will be available soon.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: matchesState.when(
        data: (matches) => RefreshIndicator(
          onRefresh: () => ref
              .read(squadMatchesNotifierProvider.notifier)
              .refresh(squadId: widget.squadId),
          child: matches.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No matches found for this squad yet.'),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return MatchTile(
                      match: match,
                      onTap: () => _openDetails(context, match),
                    );
                  },
                ),
        ),
        error: (error, stackTrace) => RefreshIndicator(
          onRefresh: () => ref
              .read(squadMatchesNotifierProvider.notifier)
              .refresh(squadId: widget.squadId),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Failed to load matches\n\n',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    TextSpan(
                      text: error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Match match) {
    context.go('/squads/${match.squadId}/matches/${match.matchId}');
  }
}
