import 'package:flutter/material.dart';

class PlayerDetailsPage extends StatelessWidget {
  const PlayerDetailsPage({
    super.key,
    required this.squadId,
    required this.playerId,
  });

  final String squadId;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player details'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Player details will be available soon.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Player ID: $playerId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Squad ID: $squadId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
