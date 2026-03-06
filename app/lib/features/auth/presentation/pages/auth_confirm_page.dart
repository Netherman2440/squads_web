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
        title: const Text('Potwierdź e-mail'),
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
                'Sprawdź skrzynkę odbiorczą',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                displayEmail != null
                    ? 'Wysłaliśmy link potwierdzający na $displayEmail.'
                    : 'Wysłaliśmy link potwierdzający na Twój e-mail.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Otwórz link, aby potwierdzić konto, a następnie zaloguj się.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Wróć do logowania'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
