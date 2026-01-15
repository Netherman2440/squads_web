import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/widgets/danger_action_button.dart';

import '../../domain/entities/squad.dart';

class DangerZoneSection extends StatefulWidget {
  const DangerZoneSection({
    super.key,
    required this.squadId,
    required this.squadName,
    required this.visibility,
    required this.onChangeName,
    required this.onChangeVisibility,
    required this.onDelete,
  });

  final String squadId;
  final String squadName;
  final SquadVisibility visibility;
  final Future<void> Function(String name) onChangeName;
  final Future<void> Function(SquadVisibility visibility) onChangeVisibility;
  final Future<void> Function() onDelete;

  static const double _maxContentWidth = 860;
  static const double _actionButtonMinWidth = 200;

  @override
  State<DangerZoneSection> createState() => _DangerZoneSectionState();
}

class _DangerZoneSectionState extends State<DangerZoneSection> {
  bool _isVisibilityExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: DangerZoneSection._maxContentWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danger Zone', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.errorContainer),
              ),
              child: Column(
                children: [
                  _DangerRow(
                    title: 'Visibility',
                    subtitle: widget.visibility == SquadVisibility.private
                        ? 'This squad is currently private.'
                        : 'This squad is currently public.',
                    actionLabel: 'Change visibility',
                    onPressed: () {
                      setState(() {
                        _isVisibilityExpanded = !_isVisibilityExpanded;
                      });
                    },
                  ),
                  if (_isVisibilityExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _VisibilityOptions(
                        current: widget.visibility,
                        onSelect: (next) async {
                          setState(() {
                            _isVisibilityExpanded = false;
                          });
                          await widget.onChangeVisibility(next);
                        },
                      ),
                    ),
                  _DividerLine(color: theme.dividerColor),
                  _DangerRow(
                    title: 'Name',
                    subtitle:
                        'This squad is currently named "${widget.squadName}".',
                    actionLabel: 'Change name',
                    onPressed: _showChangeNameDialog,
                  ),
                  _DividerLine(color: theme.dividerColor),
                  _DangerRow(
                    title: 'Manage ranking updates',
                    subtitle:
                        'Configure how match results change player rankings.',
                    actionLabel: 'Manage',
                    onPressed: () {
                      context.pushNamed(
                        AppRoute.rankingSettings.name,
                        pathParameters: {'squadId': widget.squadId},
                      );
                    },
                  ),
                  _DividerLine(color: theme.dividerColor),
                  _DangerRow(
                    title: 'Transfer ownership',
                    subtitle: 'Transfer this squad to another user.',
                    actionLabel: 'Transfer',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('TODO: Transfer ownership'),
                        ),
                      );
                    },
                  ),
                  _DividerLine(color: theme.dividerColor),
                  _DangerRow(
                    title: 'Delete squad',
                    subtitle:
                        'Once you delete a squad, there is no going back. '
                        'Please be certain.',
                    actionLabel: 'Delete',
                    onPressed: () async {
                      await widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeNameDialog() async {
    final controller = TextEditingController(text: widget.squadName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'New squad name'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final newName = result?.trim();
    if (newName == null || newName.isEmpty || newName == widget.squadName) {
      return;
    }

    await widget.onChangeName(newName);
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DangerActionButton(
            label: actionLabel,
            minWidth: DangerZoneSection._actionButtonMinWidth,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: color.withValues(alpha: 0.4),
    );
  }
}

class _VisibilityOptions extends StatelessWidget {
  const _VisibilityOptions({required this.current, required this.onSelect});

  final SquadVisibility current;
  final Future<void> Function(SquadVisibility next) onSelect;

  @override
  Widget build(BuildContext context) {
    final next = current == SquadVisibility.private
        ? SquadVisibility.public
        : SquadVisibility.private;

    final nextLabel = next == SquadVisibility.private ? 'Private' : 'Public';

    return Align(
      alignment: Alignment.centerRight,
      child: DangerActionButton(
        label: 'Change visibility to $nextLabel',
        minWidth: DangerZoneSection._actionButtonMinWidth,
        onPressed: () => onSelect(next),
      ),
    );
  }
}
