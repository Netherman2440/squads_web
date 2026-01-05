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
  ProviderSubscription<AsyncValue<AuthEntity?>>? _authSubscription;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
    _authSubscription?.close();
    _authSubscription = ref.listenManual<AsyncValue<AuthEntity?>>(
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
    _authSubscription?.close();
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
    try {
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
    } finally {
      _handlingAuthNavigation = false;
    }
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

    final actionButtonStyle = TextButton.styleFrom(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.bgLight
          : AppColors.lightSurface,
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
                child: Card(
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
                              const Icon(Icons.sports_soccer, size: 96),
                              const SizedBox(height: 16),
                              Text(
                                'Squads App',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
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
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () => isPasswordObscured =
                                        !isPasswordObscured,
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : handlePasswordReset,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
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
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
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
                              onPressed: isLoading ? null : handleGoogleSignIn,
                              icon: const Icon(Icons.g_mobiledata),
                              label: const Text('Continue with Google'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 160,
                                height: 40,
                                child: TextButton(
                                  style: actionButtonStyle,
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
                              SizedBox(
                                width: 180,
                                height: 40,
                                child: TextButton(
                                  style: actionButtonStyle,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
