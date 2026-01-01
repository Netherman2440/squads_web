import 'package:app/features/squads/domain/entities/squad_member.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:flutter/material.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.currentUserRole,
    required this.onPromote,
    required this.onDemote,
    required this.onRemove,
    required this.onAccept,
    required this.onDecline,
  });

  final SquadMember member;
  final SquadRole currentUserRole;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onRemove;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.16),
          child: Icon(Icons.person, color: colorScheme.onPrimary),
        ),
        title: Text(
          member.email,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          member.role.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: _getRoleColor(context, member.role),
          ),
        ),
        trailing: _buildActions(context),
      ),
    );
  }

  Color _getRoleColor(BuildContext context, SquadRole role) {
    final colors = Theme.of(context).colorScheme;
    switch (role) {
      case SquadRole.owner:
        return Colors.amber; // Gold-ish
      case SquadRole.admin:
        return Colors.orange;
      case SquadRole.pending:
        return colors.primary;
      case SquadRole.member:
      default:
        return colors.onSurfaceVariant;
    }
  }

  Widget? _buildActions(BuildContext context) {
    // If viewing self, typically no actions here (or different ones).
    // Assuming list doesn't filter out self, but actions might be restricted.

    if (member.role == SquadRole.owner) {
      return null; // Cannot perform actions on owner
    }

    if (member.role == SquadRole.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            color: Colors.green,
            tooltip: 'Accept',
            onPressed: onAccept,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Theme.of(context).colorScheme.error,
            tooltip: 'Decline',
            onPressed: onDecline,
          ),
        ],
      );
    }

    // Logic for Admin/Member management based on current user role
    final canManage =
        currentUserRole == SquadRole.owner ||
        (currentUserRole == SquadRole.admin && member.role == SquadRole.member);

    if (!canManage) {
      return null;
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'promote':
            onPromote?.call();
            break;
          case 'demote':
            onDemote?.call();
            break;
          case 'remove':
            onRemove?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (member.role == SquadRole.member &&
            currentUserRole == SquadRole.owner)
          const PopupMenuItem(
            value: 'promote',
            child: Text('Promote to Admin'),
          ),
        if (member.role == SquadRole.admin &&
            currentUserRole == SquadRole.owner)
          const PopupMenuItem(value: 'demote', child: Text('Demote to Member')),
        const PopupMenuItem(value: 'remove', child: Text('Remove from Squad')),
      ],
    );
  }
}
