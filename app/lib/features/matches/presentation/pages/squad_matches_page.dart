import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/app_router.dart';
import 'package:app/features/matches/presentation/controllers/squad_matches_notifier.dart';
import 'package:app/features/matches/presentation/widgets/match_tile.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';

class SquadMatchesPage extends ConsumerWidget {
  final String squadId;

  const SquadMatchesPage({super.key, required this.squadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(squadMatchesProvider(squadId));
    final squadAsync = ref.watch(squadDetailProvider(squadId));

    final bool canManage =
        squadAsync.asData?.value.role == SquadRole.owner ||
        squadAsync.asData?.value.role == SquadRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Mecze')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () {
                context.pushNamed(
                  AppRoute.draftCreate.name,
                  pathParameters: {'squadId': squadId},
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.read(squadMatchesProvider(squadId).notifier).refresh();
        },
        child: matchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return const Center(child: Text('Nie znaleziono meczów.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return MatchTile(match: match, squadId: squadId);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: SelectableText.rich(
              TextSpan(
                text: 'Błąd: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
