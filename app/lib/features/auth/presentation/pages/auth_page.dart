import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_theme.dart';
import 'package:app/core/error/failure.dart';

import '../providers/auth_notifier.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final GlobalKey<FormState> formKey;
  bool isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Handle side effects (Navigation, Errors)
    ref.listen<AsyncValue>(authStateProvider, (previous, next) {
      next.whenOrNull(
        data: (data) {
          if (data != null && mounted) {
            if (data.isAnonymous) {
              context.go('/squads');
            } else {
              context.go('/me');
            }
          }
        },
        error: (error, stackTrace) {
          String message = 'Login failed. Please try again.';

          if (error is InvalidCredentialsFailure) {
            message = 'Invalid email or password.';
          } else if (error is UserNotConfirmedFailure) {
            message = 'Email not confirmed. Please check your inbox.';
          } else if (error is NetworkFailure) {
            message =
                'Failed to connect to the server. Please try again later.';
          } else if (error is Failure) {
            message = error.message;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        },
      );
    });

    final isLoading = authState.isLoading;

    Future<void> handleLogin() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }
      // Trigger login. State listener will handle success/error.
      await ref
          .read(authStateProvider.notifier)
          .login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
    }

    Future<void> handleGuest() async {
      await ref.read(authStateProvider.notifier).guestLogin();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_soccer, size: 100),
                const SizedBox(height: 20),
                Text(
                  'Squads App',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
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
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(text)) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => isPasswordObscured = !isPasswordObscured,
                        );
                      },
                      icon: Icon(
                        isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  obscureText: isPasswordObscured,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => handleLogin(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 40,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.bgLight
                              : AppColors.lightSurface,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (!context.mounted) {
                                  return;
                                }
                                context.go('/auth/register');
                              },
                        child: const Text('Create account'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      height: 40,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.bgLight
                              : AppColors.lightSurface,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: isLoading ? null : handleGuest,
                        child: const Text('Continue as guest'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
