import 'package:flutter/material.dart';

import '../controllers/players_notifier.dart';

class PlayersSortMenu extends StatelessWidget {
  const PlayersSortMenu({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PlayersSortOption selected;
  final ValueChanged<PlayersSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<PlayersSortOption>(
      value: selected,
      onChanged: (option) {
        if (option != null) {
          onChanged(option);
        }
      },
      items: PlayersSortOption.values
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option.label),
            ),
          )
          .toList(),
      underline: const SizedBox.shrink(),
    );
  }
}
