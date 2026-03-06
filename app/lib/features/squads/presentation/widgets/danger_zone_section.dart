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
            Text('Strefa zagrożenia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error),
              ),
              child: Column(
                children: [
                  _VisibilityRow(
                    title: 'Widoczność',
                    subtitle: widget.visibility == SquadVisibility.private
                        ? 'Ten skład jest obecnie prywatny.'
                        : 'Ten skład jest obecnie publiczny.',
                    isExpanded: _isVisibilityExpanded,
                    actionLabel: 'Zmień widoczność',
                    onToggleExpanded: () {
                      setState(() {
                        _isVisibilityExpanded = !_isVisibilityExpanded;
                      });
                    },
                    nextLabel: widget.visibility == SquadVisibility.private
                        ? 'Zmień na publiczny'
                        : 'Zmień na prywatny',
                    onConfirm: () async {
                      final next = widget.visibility == SquadVisibility.private
                          ? SquadVisibility.public
                          : SquadVisibility.private;
                      setState(() {
                        _isVisibilityExpanded = false;
                      });
                      await widget.onChangeVisibility(next);
                    },
                  ),
                  _DividerLine(color: theme.colorScheme.error),
                  _DangerRow(
                    title: 'Nazwa',
                    subtitle:
                        'Ten skład ma obecnie nazwę "${widget.squadName}".',
                    actionLabel: 'Zmień nazwę',
                    onPressed: _showChangeNameDialog,
                  ),
                  _DividerLine(color: theme.colorScheme.error),
                  _DangerRow(
                    title: 'Zarządzaj aktualizacją rankingu',
                    subtitle:
                        'Skonfiguruj, jak wyniki meczów zmieniają rankingi graczy.',
                    actionLabel: 'Zarządzaj',
                    onPressed: () {
                      context.pushNamed(
                        AppRoute.rankingSettings.name,
                        pathParameters: {'squadId': widget.squadId},
                      );
                    },
                  ),
                  _DividerLine(color: theme.colorScheme.error),
                  _DangerRow(
                    title: 'Przekaż własność',
                    subtitle: 'Przekaż ten skład innemu użytkownikowi.',
                    actionLabel: 'Przekaż',
                    onPressed: null,
                  ),
                  _DividerLine(color: theme.colorScheme.error),
                  _DangerRow(
                    title: 'Usuń skład',
                    subtitle:
                        'Po usunięciu składu nie będzie odwrotu. '
                        'Upewnij się, że tego chcesz.',
                    actionLabel: 'Usuń',
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
          title: const Text('Zmień nazwę'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nowa nazwa składu'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Zapisz'),
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
  final VoidCallback? onPressed;

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
      color: color.withValues(alpha: 0.5),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.actionLabel,
    required this.onToggleExpanded,
    required this.nextLabel,
    required this.onConfirm,
  });

  final String title;
  final String subtitle;
  final bool isExpanded;
  final String actionLabel;
  final VoidCallback onToggleExpanded;
  final String nextLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DangerActionButton(
                label: actionLabel,
                minWidth: DangerZoneSection._actionButtonMinWidth,
                onPressed: onToggleExpanded,
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                DangerActionButton(
                  label: nextLabel,
                  minWidth: DangerZoneSection._actionButtonMinWidth,
                  onPressed: onConfirm,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
