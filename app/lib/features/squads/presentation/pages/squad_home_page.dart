import 'package:flutter/material.dart';

import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';

class SquadHomePage extends StatelessWidget {
  const SquadHomePage({
    super.key,
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
          child: _SquadHomeGrid(),
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

class _SquadHomeGrid extends StatelessWidget {
  const _SquadHomeGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tiles = [
      _SquadHomeTileData(
        icon: Icons.person,
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
                  color: theme.colorScheme.surfaceContainerHighest,
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


