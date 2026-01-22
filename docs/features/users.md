# Users Feature Implementation Plan

## Overview
This feature handles the current user's profile management. It is designed to be minimal for the MVP, focusing on identity (email, id) and serving as the context for the "My Profile" page.

## Directory Structure
`lib/features/users/`
- `domain/`
    - `entities/`
        - `user.dart`
    - `repositories/`
        - `user_repository.dart`
- `application/`
    - `get_current_user_use_case.dart`
    - `update_user_use_case.dart`
- `infrastructure/`
    - `repositories/`
        - `supabase_user_repository.dart`
- `presentation/`
    - `pages/`
        - `user_page.dart`
    - `widgets/`
        - `user_profile_card.dart`
    - `state/`
        - `user_notifier.dart`
        - `user_state.dart`

## Detailed Plan

### 1. Domain Layer
**Entities:**
- `User`:
    - `id`: String (UUID)
    - `email`: String
    - Note: `User` is intentionally **not** coupled to squads or roles; the
      user–squad relation is modeled in the `squads` feature as the
      `Membership` entity.

**Repositories (Interface):**
- `UserRepository`:
    - `Future<User?> getCurrentUser()`
    - `Future<void> updateUser(User user)` (Mock for MVP, as email/password changes are handled by Auth feature usually, or not in MVP scope)

### 2. Infrastructure Layer
**SupabaseUserRepository:**
- Implements `UserRepository`.
- Uses `SupabaseClient`.
- **Get Current User**:
    - Access `supabase.auth.currentUser`.
    - Map the Supabase `User` object to our Domain `User` entity.
- **Update User**:
    - Mock implementation for now (or simple metadata update if needed later).

### 3. Application Layer
**Use Cases:**
- `GetCurrentUserUseCase`:
    - Returns the currently authenticated user entity.
    - Returns `null` if not logged in.

- `UpdateUserUseCase`:
    - Accepts `User` entity.
    - Calls `repository.updateUser()`.
    - (Currently a placeholder for future profile editing).

### 4. Presentation Layer
**State Management (Riverpod):**
- `UserState`:
    - `isLoading`: bool
    - `user`: User?
    - `error`: String?
- `UserNotifier` (Notifier/AsyncNotifier):
    - `loadUser()`: Calls `GetCurrentUserUseCase`.

**UI Components:**
- `UserPage` (`/me`):
    - **Orchestration Role**:
        - Watches `UserNotifier` to display user details (Email).
        - Watches `SquadsNotifier` (from `features/squads`) to display "My Squads".
    - **Layout**:
        - `UserProfileCard`: Displays email and avatar placeholder.
        - `SquadQuickList` (or reused `SquadListItem`): Displays list of squads where user is a member/owner.
        - CTA: "Create Squad" (Navigates to Create Squad flow).

## Dependencies
- `supabase_flutter`
- `flutter_riverpod`
- `features/squads` (Presentation layer dependency only, for displaying squad lists)

### Design updates (user profile + memberships)

- The `User` entity in `features/users/domain/entities/user.dart` now contains only
  identity data (`id`, `email`). It does **not** store squad roles or memberships;
  the many-to-many relation lives in the squads feature as the `Membership` entity.
- `UserRepository` exposes only user-centric operations:
  `getCurrentUser()` and `updateUser(User user)` (still a mock for MVP).
- `GetCurrentUserUseCase` has been extended to compose data from three repositories:
  `UserRepository`, `MembershipRepository` and `SquadRepository`. It returns a
  `UserProfileSummary` that contains the current `User` plus a list of
  `UserMembershipItem` objects (each with `squadId`, `squadName`, `memberCount`
  and the user's `SquadRole` in that squad).
- `UserState` in presentation now holds `UserProfileSummary?` instead of just `User?`,
  and `UserNotifier.loadUser()` writes the full summary into the state.
- `UserPage` (`/me`) renders:
  - `UserProfileCard` based on `UserProfileSummary.user`,
  - a "My Squads" section based on `UserMembershipItem` list,
  - a "Create Squad" CTA only when the user does **not** already own a squad
    (no membership with `role == owner`), mirroring the domain owner-limit rule.

