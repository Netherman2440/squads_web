import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_theme.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:app/features/auth/domain/entities/auth_provider.dart';
import 'package:app/features/auth/application/request_password_reset_use_case.dart';
import 'package:app/features/squads/application/join_squad_from_invite_use_case.dart';
import 'package:app/features/squads/infrastructure/storage/invite_code_storage.dart';

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
  bool _processingInvite = false;
  bool _handlingAuthNavigation = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
    ref.listenManual<AsyncValue<AuthEntity?>>(
      authStateProvider,
      (previous, next) {
        next.when(
          data: (data) {
            _handleAuthSuccess(data);
          },
          error: (error, stackTrace) {
            _handleAuthError(error);
          },
          loading: () {},
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> _joinPendingInvite() async {
    if (_processingInvite) {
      return null;
    }

    _processingInvite = true;
    try {
      final squadId = await ref
          .read(joinSquadFromInviteUseCaseProvider)
          .execute();
      return squadId;
    } catch (error) {
      await ref.read(inviteCodeStorageProvider).clear();
      if (!mounted) {
        return null;
      }
      var message = 'Invite code is invalid or expired.';
      if (error is Failure && error.message.isNotEmpty) {
        message = error.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return null;
    } finally {
      _processingInvite = false;
    }
  }

  Future<void> _handleAuthSuccess(AuthEntity? data) async {
    if (data == null || !mounted || _handlingAuthNavigation) {
      return;
    }
    _handlingAuthNavigation = true;

    if (data.isAnonymous) {
      context.go('/squads');
      return;
    }

    final joinedSquadId = await _joinPendingInvite();
    if (!mounted) {
      return;
    }

    if (joinedSquadId != null) {
      context.go('/squads/$joinedSquadId');
      return;
    }

    context.go('/me');
  }

  void _handleAuthError(Object error) {
    if (!mounted) {
      return;
    }

    String message = 'Login failed. Please try again.';

    if (error is InvalidCredentialsFailure) {
      message = 'Invalid email or password.';
    } else if (error is UserNotConfirmedFailure) {
      message = 'Email not confirmed. Please check your inbox.';
    } else if (error is NetworkFailure) {
      message = 'Failed to connect to the server. Please try again later.';
    } else if (error is Failure) {
      message = error.message;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

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

    Future<void> handleGoogleSignIn() async {
      final redirectTo = '${Uri.base.origin}/#/auth/callback';
      await ref.read(authStateProvider.notifier).signInWithProvider(
        provider: AuthProvider.google,
        redirectTo: redirectTo,
      );
    }

    Future<void> handlePasswordReset() async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final messenger = ScaffoldMessenger.of(context);

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.emailAddress,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Send link'),
            ),
          ],
        ),
      );

      if (result != true) {
        controller.dispose();
        return;
      }

      final email = controller.text.trim();
      controller.dispose();
      try {
        final redirectTo = '${Uri.base.origin}/#/auth/reset';
        await ref
            .read(requestPasswordResetUseCaseProvider)
            .execute(email, redirectTo: redirectTo);
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent. Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        var message = 'Failed to send reset link.';
        if (error is Failure) {
          message = error.message;
        }
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : handlePasswordReset,
                  child: const Text('Forgot password?'),
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
