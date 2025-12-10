import 'package:flutter/material.dart';

class EmptyPlayersState extends StatelessWidget {
  const EmptyPlayersState({
    super.key,
    required this.canAdd,
    this.onAdd,
  });

  final bool canAdd;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_outlined,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text('No players in this squad yet.'),
          const SizedBox(height: 8),
          if (canAdd)
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first player'),
            ),
        ],
      ),
    );
  }
}
