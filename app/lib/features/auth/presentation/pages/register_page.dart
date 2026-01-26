import 'package:app/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/auth_provider.dart';
import '../providers/auth_notifier.dart';
import '../widgets/brand_header.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final TextEditingController fullNameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmController;
  late final GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmController = TextEditingController();
    formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    // Listen for authentication state changes
    ref.listen(authStateProvider, (previous, next) {
      next.whenOrNull(
        data: (data) async {
          if (data != null) {
            if (data.accessToken.isNotEmpty) {
              await ref.read(authStateProvider.notifier).logout();
            }
            if (!context.mounted) {
              return;
            }
            final email = emailController.text.trim();
            final encoded = Uri.encodeComponent(
              email.isEmpty ? data.email : email,
            );
            context.go('/auth/confirm?email=$encoded');
          }
        },
        error: (error, stack) {
          String message = 'Registration failed. Please try again.';
          if (error is UserAlreadyExistsFailure) {
            message = 'An account with this email already exists.';
          } else if (error is NetworkFailure) {
            message = 'No internet connection.';
          } else if (error is Failure) {
            message = error.message;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        },
      );
    });

    Future<void> handleRegister() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      await ref
          .read(authStateProvider.notifier)
          .register(
            fullName: fullNameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      // Navigation is handled by listener
    }

    Future<void> handleGoogleSignIn() async {
      final redirectTo = '${Uri.base.origin}/#/auth/callback';
      await ref
          .read(authStateProvider.notifier)
          .signInWithProvider(
            provider: AuthProvider.google,
            redirectTo: redirectTo,
          );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          const maxCardWidth = 420.0;
          final horizontalPadding = constraints.maxWidth < 600 ? 24.0 : 48.0;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxCardWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandHeader(maxWidth: maxCardWidth),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Register an account',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter full name';
                                  }
                                  if (text.length < 2) {
                                    return 'Full name is too short';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                textCapitalization: TextCapitalization.none,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter email';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  );
                                  if (!emailRegex.hasMatch(text)) {
                                    return 'Please enter valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final text = value ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (text.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: confirmController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => handleRegister(),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : handleRegister,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Sign up'),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : handleGoogleSignIn,
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: const Text('Sign up with Google'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (context.mounted) {
                                          context.go('/auth');
                                        }
                                      },
                                child: const Text('Already have an account?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
