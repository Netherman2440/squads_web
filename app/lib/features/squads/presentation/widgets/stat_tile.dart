import 'package:flutter/material.dart';

import 'package:app/features/players/domain/entities/player.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = _formatValue(value);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(label),
      trailing: Text(
        valueText,
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.right,
      ),
    );
  }

  String _formatValue(Object? value) {
    if (value == null) {
      return '-';
    }
    if (value is Player) {
      return value.name;
    }
    if (value is num) {
      final number = value.toDouble();
      if ((number - number.roundToDouble()).abs() < 0.0001) {
        return number.toInt().toString();
      }
      return number.toStringAsFixed(2);
    }
    return value.toString();
  }
}
