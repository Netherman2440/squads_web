import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/error/failure.dart';
import '../providers/auth_notifier.dart';

class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  bool _handled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handled) {
      return;
    }
    _handled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authStateProvider.notifier).completeOAuthSignIn(Uri.base);
      if (!mounted) {
        return;
      }
      final authState = ref.read(authStateProvider);
      authState.whenOrNull(
        data: (data) {
          if (data != null && mounted) {
            context.go('/auth');
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final error = authState.error;
    final hasError = authState.hasError;
    String? message;

    if (hasError) {
      if (error is Failure) {
        message = error.message;
      } else {
        message = 'Sign in failed. Please try again.';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signing in'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.login,
                size: 72,
                color: hasError ? theme.colorScheme.error : null,
              ),
              const SizedBox(height: 16),
              Text(
                hasError ? 'Unable to sign in' : 'Finishing sign in',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'Please wait while we connect your account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!hasError)
                const CircularProgressIndicator()
              else
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
