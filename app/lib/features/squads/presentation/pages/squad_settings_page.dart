import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/squad_member.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:app/features/squads/presentation/state/squad_settings_notifier.dart';
import 'package:app/features/squads/presentation/widgets/member_tile.dart';

class SquadSettingsPage extends ConsumerStatefulWidget {
  const SquadSettingsPage({
    super.key,
    required this.squadId,
  });

  final String squadId;

  @override
  ConsumerState<SquadSettingsPage> createState() =>
      _SquadSettingsPageState();
}

class _SquadSettingsPageState extends ConsumerState<SquadSettingsPage> {
  late final TextEditingController _nameController;
  SquadVisibility? _visibilityDraft;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    Future.microtask(() async {
      await ref.read(squadSettingsProvider.notifier).load(widget.squadId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersState = ref.watch(squadSettingsProvider);
    final squadState = ref.watch(squadDetailProvider(widget.squadId));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: squadState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _SettingsErrorView(error: error),
            data: (squad) {
              if (squad.role != SquadRole.owner) {
                return const _NoAccessView();
              }

              _ensureInitializedFromSquad(squad);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members & Settings',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage squad members, roles and visibility.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    _MembersSection(
                      membersState: membersState,
                      currentUserRole: squad.role,
                      onPromote: (member) async {
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .promoteToAdmin(member.userId);
                      },
                      onDemote: (member) async {
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .demoteToMember(member.userId);
                      },
                      onRemove: (member) async {
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .removeFromSquad(member.userId);
                      },
                      onAccept: (member) async {
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .acceptRequest(member.userId);
                      },
                      onDecline: (member) async {
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .declineRequest(member.userId);
                      },
                    ),
                    const SizedBox(height: 24),
                    const _InviteSection(),
                    const SizedBox(height: 24),
                    _DangerZoneSection(
                      nameController: _nameController,
                      visibilityDraft: _visibilityDraft!,
                      onVisibilityChanged: (visibility) {
                        setState(() {
                          _visibilityDraft = visibility;
                        });
                      },
                      onSaveName: () async {
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .updateName(_nameController.text);
                        ref.invalidate(
                          squadDetailProvider(widget.squadId),
                        );
                      },
                      onSaveVisibility: () async {
                        final visibility = _visibilityDraft;
                        if (visibility == null) {
                          return;
                        }
                        await ref
                            .read(squadSettingsProvider.notifier)
                            .updateVisibility(visibility);
                        ref.invalidate(
                          squadDetailProvider(widget.squadId),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _ensureInitializedFromSquad(Squad squad) {
    if (_nameController.text.isEmpty) {
      _nameController.text = squad.name;
    }
    _visibilityDraft ??= squad.visibility;
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.membersState,
    required this.currentUserRole,
    required this.onPromote,
    required this.onDemote,
    required this.onRemove,
    required this.onAccept,
    required this.onDecline,
  });

  final AsyncValue<List<SquadMember>> membersState;
  final SquadRole currentUserRole;
  final Future<void> Function(SquadMember member) onPromote;
  final Future<void> Function(SquadMember member) onDemote;
  final Future<void> Function(SquadMember member) onRemove;
  final Future<void> Function(SquadMember member) onAccept;
  final Future<void> Function(SquadMember member) onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        membersState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => _SettingsErrorView(error: error),
          data: (members) {
            if (members.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SelectableText(
                  'No members found for this squad.',
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return MemberTile(
                  member: member,
                  currentUserRole: currentUserRole,
                  onPromote: () => onPromote(member),
                  onDemote: () => onDemote(member),
                  onRemove: () => onRemove(member),
                  onAccept: () => onAccept(member),
                  onDecline: () => onDecline(member),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _InviteSection extends StatelessWidget {
  const _InviteSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mockLink = 'https://squads.app/invite/mock-link';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite link',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            mockLink,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () {
                  // TODO: integrate with Clipboard & real invite link
                },
                child: const Text('Copy link'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: integrate with GenerateInviteLinkUseCase
                },
                child: const Text('Regenerate'),
              ),
              const Spacer(),
              Text(
                'Valid for 24h (mocked).',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({
    required this.nameController,
    required this.visibilityDraft,
    required this.onVisibilityChanged,
    required this.onSaveName,
    required this.onSaveVisibility,
  });

  final TextEditingController nameController;
  final SquadVisibility visibilityDraft;
  final ValueChanged<SquadVisibility> onVisibilityChanged;
  final Future<void> Function() onSaveName;
  final Future<void> Function() onSaveVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha:0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.errorContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger zone',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be careful when changing these settings. '
            'They affect access to your squad.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Squad name',
            ),
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onSaveName,
              child: const Text('Save name'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SquadVisibility>(
                  initialValue: visibilityDraft,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                  ),
                  items: SquadVisibility.values
                      .map(
                        (v) => DropdownMenuItem<SquadVisibility>(
                          value: v,
                          child: Text(v.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onVisibilityChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: onSaveVisibility,
                child: const Text('Save visibility'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: null,
            child: const Text(
              'Delete squad (coming soon)',
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  const _SettingsErrorView({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Error\n\n',
              style: textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: error.toString(),
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccessView extends StatelessWidget {
  const _NoAccessView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'No access\n\n',
                style: textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text:
                    'Only the squad owner can access squad settings page.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


