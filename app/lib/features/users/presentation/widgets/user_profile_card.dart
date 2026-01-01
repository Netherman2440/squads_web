import 'package:flutter/material.dart';

import 'package:app/features/users/domain/entities/user.dart';

class UserProfileCard extends StatelessWidget {
  final bool isLoading;
  final User? user;
  final String? error;

  const UserProfileCard({
    super.key,
    required this.isLoading,
    required this.user,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && error!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText.rich(
          TextSpan(
            text: 'Error: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'You are not logged in.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user!.email,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User ID: ${user!.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
