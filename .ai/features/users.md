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

