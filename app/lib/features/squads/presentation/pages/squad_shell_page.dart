import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/players/presentation/widgets/create_player_dialog.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/pages/squad_home_page.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';

class SquadShellPage extends ConsumerWidget {
  const SquadShellPage({super.key, required this.squadId});

  final String squadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(squadDetailProvider(squadId));

    return Scaffold(
      floatingActionButton: state.maybeWhen(
        data: (squad) => _QuickActionsFab(squad: squad),
        orElse: () => null,
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _SquadShellErrorView(
            error: error,
            onBack: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.goNamed(AppRoute.squads.name);
            },
          ),
          data: (squad) => SquadHomePage(squad: squad),
        ),
      ),
    );
  }
}

class _SquadShellErrorView extends StatelessWidget {
  const _SquadShellErrorView({required this.error, required this.onBack});

  final Object error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    String title = 'Coś poszło nie tak';
    String message = 'Wystąpił nieoczekiwany błąd podczas ładowania składu.';
    IconData icon = Icons.error_outline;

    if (error is NotFoundFailure) {
      title = 'Nie znaleziono składu';
      message = 'Szukany skład nie istnieje.';
    } else if (error is UnauthorizedFailure) {
      title = 'No access';
      message = 'Nie masz dostępu do tego składu.';
      icon = Icons.lock_outline;
    } else if (error is Failure) {
      message = error.message;
    }

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n\n',
                    style: textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: onBack,
                child: const Text('Wróć do listy składów'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsFab extends StatelessWidget {
  const _QuickActionsFab({required this.squad});

  final Squad squad;

  bool get _canManageContent =>
      squad.role == SquadRole.owner || squad.role == SquadRole.admin;

  @override
  Widget build(BuildContext context) {
    if (!_canManageContent) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => _QuickActionsSheet(squad: squad),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Szybkie akcje'),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({required this.squad});

  final Squad squad;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Szybkie akcje',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Wybierz, co chcesz dodać do ${squad.name}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Dodaj gracza'),
              subtitle: const Text('Zaproś lub utwórz nowego gracza składu.'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog<void>(
                  context: context,
                  builder: (context) =>
                      CreatePlayerDialog(squadId: squad.squadId),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Dodaj mecz'),
              subtitle: const Text('Zaplanuj nowy mecz składu.'),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed(
                  AppRoute.draftCreate.name,
                  pathParameters: {'squadId': squad.squadId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Dodaj turniej'),
              subtitle: const Text('Utwórz nowy turniej dla tego składu.'),
              onTap: () {
                Navigator.of(context).pop();
                _showPlaceholderDialog(context, title: 'Dodaj turniej');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderDialog(BuildContext context, {required String title}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const SelectableText(
          'Ta akcja będzie dostępna w kolejnej wersji aplikacji.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}
