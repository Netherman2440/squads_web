import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthConfirmPage extends StatelessWidget {
  const AuthConfirmPage({super.key, required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEmail = email?.isNotEmpty == true ? email : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm email'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 80),
              const SizedBox(height: 16),
              Text(
                'Check your inbox',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                displayEmail != null
                    ? 'We sent a confirmation link to $displayEmail.'
                    : 'We sent a confirmation link to your email.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Open the link to verify your account, then log in.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
