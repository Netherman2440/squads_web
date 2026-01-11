import 'package:flutter/material.dart';

import '../../domain/entities/squad.dart';
import '../../domain/entities/user_squad_role.dart';

class SquadListItem extends StatelessWidget {
  const SquadListItem({
    super.key,
    required this.squad,
    required this.isGuest,
    required this.onTap,
  });

  final Squad squad;
  final bool isGuest;
  final VoidCallback onTap;

  IconData get _visibilityIcon =>
      squad.visibility == SquadVisibility.private ? Icons.lock : Icons.group;

  Color _roleColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (squad.role) {
      case SquadRole.owner:
        return colorScheme.primary;
      case SquadRole.admin:
        return colorScheme.secondary;
      case SquadRole.member:
        return colorScheme.tertiary;
      case SquadRole.pending:
        return colorScheme.tertiaryContainer;
      case SquadRole.invited:
        return colorScheme.secondaryContainer;
      case SquadRole.declined:
      case SquadRole.removed:
        return colorScheme.errorContainer;
      case SquadRole.none:
        return colorScheme.outline;
      case SquadRole.guest:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_visibilityIcon)),
        title: Text(squad.name),
        subtitle: Row(
          children: [
            Icon(
              Icons.sports_soccer,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(squad.sportType.label),
          ],
        ),
        trailing: squad.role == SquadRole.none
            ? (squad.visibility == SquadVisibility.private
                  ? Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.outline,
                      size: 20,
                    )
                  : null)
            : Chip(
                label: Text(
                  isGuest && squad.role == SquadRole.none
                      ? 'Guest'
                      : squad.role.label,
                ),
                backgroundColor: _roleColor(context).withValues(alpha: 0.15),
                labelStyle: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _roleColor(context)),
              ),
        onTap: onTap,
      ),
    );
  }
}
