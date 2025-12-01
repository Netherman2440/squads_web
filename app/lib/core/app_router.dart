import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/pages/auth_page.dart';
import 'package:app/features/auth/presentation/pages/register_page.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/presentation/pages/squads_page.dart';
import 'package:app/features/users/presentation/pages/user_page.dart';
import 'package:app/features/squads/presentation/pages/squad_shell_page.dart';

enum AppRoute {
  auth,
  authRegister,
  squads,
  settings,
  profile,
  squadDetails,
}

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      name: AppRoute.auth.name,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AuthPage(),
      ),
    ),
    GoRoute(
      path: '/auth/register',
      name: AppRoute.authRegister.name,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: RegisterPage(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => RootShell(
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/squads',
          name: AppRoute.squads.name,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SquadsPage(),
          ),
        ),
        GoRoute(  
          path: '/squads/:squadId',
          name: AppRoute.squadDetails.name,
          pageBuilder: (context, state) {
            final squadId = state.pathParameters['squadId'] ?? '';
            return NoTransitionPage(
              child: SquadShellPage(squadId: squadId),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          name: AppRoute.settings.name,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/me',
          name: AppRoute.profile.name,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: UserPage(),
          ),
        ),
      ],
    ),
  ],
);

class RootShell extends StatelessWidget {
  const RootShell({
    super.key,
    required this.child,
  });

  final Widget child;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authStateProvider);
            final authEntity = authState.authEntity;
            final isGuest = authEntity == null || authEntity.isAnonymous;

            if (isGuest) {
              return AppBar(
                title: const Text('Squads'),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      context.go('/auth');
                    },
                    icon: const Icon(
                      Icons.login,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Zaloguj',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }

            final email = authEntity.email;

            return AppBar(
              title: const Text('Squads'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 12,
                  ),
                  child: PopupMenuButton<_ProfileMenuAction>(
                    tooltip: email,
                    position: PopupMenuPosition.under,
                    onSelected: (action) async {
                      switch (action) {
                        case _ProfileMenuAction.profile:
                          context.go('/me');
                          break;
                        case _ProfileMenuAction.logout:
                          await ref.read(authStateProvider.notifier).logout();
                          if (!context.mounted) {
                            return;
                          }
                          context.go('/auth');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<_ProfileMenuAction>(
                        value: _ProfileMenuAction.profile,
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Profile'),
                          subtitle: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<_ProfileMenuAction>(
                        value: _ProfileMenuAction.logout,
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Wyloguj'),
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          email,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }
}

enum _ProfileMenuAction {
  profile,
  logout,
}


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings screen'),
    );
  }
}
