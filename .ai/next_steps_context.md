# Next Steps Context

## Current Status
- **Auth Feature**: Completed "Vertical Slice" with robust error handling.
  - Repository uses explicit `try-catch` and maps Supabase exceptions to Domain `Failure`s.
  - Notifier uses `AsyncValue` and `AsyncValue.guard` to handle states safely.
  - UI uses `ref.listen` to display granular error messages (SnackBars) and handle navigation.
  - `Failure` hierarchy defined in `core/error/failure.dart` (Validation, Network, Auth, Server, etc.).

## Goal for Next Session
Implement **Squads Feature Vertical Slice** with the same architectural standards.

## Key Tasks
1. **Global Loading Page**: 
   - Create a reusable `LoadingPage` or `LoadingOverlay` for blocking async operations (like creating a squad) if needed, or stick to `AsyncValue` loading states within widgets.
   - Decision: Prefer localized loading states (`isLoading` in button) for better UX, but support full-page loading for initial fetches.

2. **Squads Feature Refactoring**:
   - **Domain**: Ensure `Squad` entity and `SquadRepository` interface are clean.
   - **Infrastructure**: Refactor `SupabaseSquadRepository` to use `try-catch` + `toFailure()` extension (handling RLS errors `42501` and `PGRST116` for 404).
   - **Application**: Use Cases should just call repo (no `AsyncValue` here).
   - **Presentation**: Refactor `SquadsNotifier` to use `AsyncValue<List<Squad>>`.
   - **UI**: 
     - Refactor `SquadsPage` using `.when` for loading/error/data states.
     - Handle "Access Denied" / "Not Found" logic (unified error screen vs redirects).

## Architectural Guidelines to Follow
- **Repository**: ALWAYS use `try-catch`. Log errors using `logging` package. Throw `e.toFailure()`.
- **Notifier**: Extend `Notifier<AsyncValue<T>>`. Use `state = await AsyncValue.guard(() => useCase.execute())`.
- **UI**: Use `ref.listen` for one-off errors (SnackBars). Use `.when` for build logic.

