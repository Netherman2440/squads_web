import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/root_shell.dart';
import 'package:app/features/auth/presentation/pages/auth_page.dart';
import 'package:app/features/auth/presentation/pages/register_page.dart';
import 'package:app/features/squads/presentation/pages/squads_page.dart';
import 'package:app/features/users/presentation/pages/user_page.dart';
import 'package:app/features/squads/presentation/pages/squad_shell_page.dart';

enum AppRoute {
  auth,
  authRegister,
  squads,
  squadHome,
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
          path: '/squads/:squadId/home',
          name: AppRoute.squadHome.name,
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings screen'),
    );
  }
}
