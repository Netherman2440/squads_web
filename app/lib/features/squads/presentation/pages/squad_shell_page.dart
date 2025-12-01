import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/squads/application/get_squad_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';

class SquadShellPage extends ConsumerWidget {
  const SquadShellPage({
    super.key,
    required this.squadId,
  });

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
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) =>
              _SquadShellErrorView(error: error, onBack: () => context.go('/home')),
          data: (squad) => _SquadShellSuccessView(squad: squad),
        ),
      ),
    );
  }
}

class _SquadShellErrorView extends StatelessWidget {
  const _SquadShellErrorView({
    required this.error,
    required this.onBack,
  });

  final Object error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String message = 'An unexpected error occurred while loading the squad.';

    if (error is SquadFailure) {
      final typedError = error as SquadFailure;
      switch (typedError.type) {
        case SquadFailureType.notFound:
          title = 'Squad not found';
          message = 'The squad you are looking for does not exist.';
          break;
        case SquadFailureType.forbidden:
          title = 'No access';
          message = 'You do not have access to this squad.';
          break;
        case SquadFailureType.unexpected:
          break;
      }
    }

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              error is SquadFailure &&
                      (error as SquadFailure).type ==
                          SquadFailureType.forbidden
                  ? Icons.lock_outline
                  : Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
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
                child: const Text('Back to squads list'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquadShellSuccessView extends StatelessWidget {
  const _SquadShellSuccessView({
    required this.squad,
  });

  final Squad squad;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SquadHeader(squad: squad),
        const SizedBox(height: 16),
        const Expanded(
          child: _SquadHome(),
        ),
      ],
    );
  }
}

class _SquadHeader extends StatelessWidget {
  const _SquadHeader({
    required this.squad,
  });

  final Squad squad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrivate = squad.visibility == SquadVisibility.private;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  squad.name,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPrivate
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrivate ? Icons.lock : Icons.public,
                            size: 16,
                            color: isPrivate
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPrivate ? 'Private' : 'Public',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isPrivate
                                  ? theme.colorScheme.onErrorContainer
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${squad.memberCount} members',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (squad.role == SquadRole.owner ||
              squad.role == SquadRole.admin ||
              squad.role == SquadRole.member)
            IconButton(
              onPressed: () {
                // TODO: navigate to squad settings in future iteration
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.settings),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '0',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionsFab extends StatelessWidget {
  const _QuickActionsFab({
    required this.squad,
  });

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
          builder: (context) => _QuickActionsSheet(squad: squad),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Quick actions'),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({
    required this.squad,
  });

  final Squad squad;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what you want to add to ${squad.name}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add player'),
              subtitle: const Text('Invite or create a new squad player.'),
              onTap: () {
                Navigator.of(context).pop();
                _showPlaceholderDialog(
                  context,
                  title: 'Add player',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Add match'),
              subtitle: const Text('Schedule a new squad match.'),
              onTap: () {
                Navigator.of(context).pop();
                _showPlaceholderDialog(
                  context,
                  title: 'Add match',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Add tournament'),
              subtitle: const Text('Create a new tournament for this squad.'),
              onTap: () {
                Navigator.of(context).pop();
                _showPlaceholderDialog(
                  context,
                  title: 'Add tournament',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderDialog(
    BuildContext context, {
    required String title,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const SelectableText(
          'This action will be implemented in a future version of the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SquadHome extends StatelessWidget {
  const _SquadHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tiles = [
      _SquadHomeTileData(
        icon: Icons.group,
        title: 'Players',
        description: 'Manage squad players and their profiles.',
      ),
      _SquadHomeTileData(
        icon: Icons.sports_soccer,
        title: 'Matches',
        description: 'Schedule and review squad matches.',
      ),
      _SquadHomeTileData(
        icon: Icons.emoji_events,
        title: 'Tournaments',
        description: 'Organize and track tournaments.',
      ),
      _SquadHomeTileData(
        icon: Icons.bar_chart,
        title: 'Stats',
        description: 'See performance analytics for your squad.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final crossAxisCount = isWide ? 4 : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 1.2 : 1,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return InkWell(
              onTap: () {
                // For now show simple placeholder text
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(tile.title),
                    content: const SelectableText(
                      'This page is coming soon.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      tile.icon,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tile.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tile.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SquadHomeTileData {
  const _SquadHomeTileData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}


