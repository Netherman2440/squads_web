import 'package:go_router/go_router.dart';

import 'package:app/core/root_shell.dart';
import 'package:app/features/auth/presentation/pages/auth_page.dart';
import 'package:app/features/auth/presentation/pages/register_page.dart';
import 'package:app/features/draft/presentation/pages/draft_results_page.dart';
import 'package:app/features/draft/presentation/pages/draft_selection_page.dart';
import 'package:app/features/squads/presentation/pages/squad_settings_page.dart';
import 'package:app/features/players/presentation/pages/players_page.dart';
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
  players,
  draftSelection,
  draftCreate,
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
          path: '/squads/:squadId/players',
          name: AppRoute.players.name,
          pageBuilder: (context, state) {
            final squadId = state.pathParameters['squadId'] ?? '';
            return NoTransitionPage(
              child: PlayersPage(squadId: squadId),
            );
          },
        ),
        GoRoute(
          path: '/squads/:squadId/matches/draft',
          name: AppRoute.draftSelection.name,
          pageBuilder: (context, state) {
            final squadId = state.pathParameters['squadId'] ?? '';
            return NoTransitionPage(
              child: DraftSelectionPage(squadId: squadId),
            );
          },
        ),
        GoRoute(
          path: '/squads/:squadId/matches/create',
          name: AppRoute.draftCreate.name,
          pageBuilder: (context, state) {
            final squadId = state.pathParameters['squadId'] ?? '';
            final extra = state.extra;
            final selectedIds = extra is List<String> ? extra : const <String>[];

            return NoTransitionPage(
              child: DraftResultsPage(
                squadId: squadId,
                selectedPlayerIds: selectedIds,
              ),
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
          path: '/squads/:squadId/settings',
          name: AppRoute.settings.name,
          pageBuilder: (context, state) {
            final squadId = state.pathParameters['squadId'] ?? '';
            return NoTransitionPage(
              child: SquadSettingsPage(squadId: squadId),
            );
          },
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
