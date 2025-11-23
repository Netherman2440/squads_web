# Squads Feature Implementation Plan

## Overview
This feature handles the management of squads , including listing, creating, and joining squads. It adheres to Clean Architecture and Feature-first organization.

## Directory Structure
`lib/features/squads/`
- `domain/`
    - `entities/`
        - `squad.dart`
        - `user_squad_role.dart`
    - `repositories/`
        - `squad_repository.dart`
- `application/`
    - `get_squads_use_case.dart`
    - `create_squad_use_case.dart`
    - `apply_to_squad_use_case.dart`
- `infrastructure/`
    - `repositories/`
        - `supabase_squad_repository.dart`
    - `data_sources/` (Optional, if direct supabase calls are complex)
- `presentation/`
    - `pages/`
        - `squads_page.dart`
    - `widgets/`
        - `squad_list_item.dart`
    - `state/`
        - `squads_state.dart`
        - `squads_notifier.dart`

## Detailed Plan

### 1. Domain Layer
**Entities:**
- `SquadRole` (Enum):
    - Values: `none`, `owner`, `admin`, `member`, `pending`, `invited`, `declined`, `removed`.
    - `none` is the default state for users with no relationship to the squad.

- `Squad`:
    - `id`: String (UUID)
    - `ownerId`: String (UUID)
    - `name`: String
    - `visibility`: Enum (`public`, `private`)
    - `sportType`: Enum (`football`)
    - `createdAt`: DateTime
    - `memberCount`: int (computed/joined)
    - `role`: `SquadRole` (Current user's role in this squad, default: `none`)

**Repositories (Interface):**
- `SquadRepository`:
    - `Future<List<Squad>> getSquads({SquadVisibility? visibility, String? searchQuery, String? sportType})`
    - `Future<List<Squad>> getUserSquads(String userId)`
    - `Future<void> createSquad(String name, SquadVisibility visibility, String ownerId, String sportType)`
    - `Future<void> applyToSquad(String squadId, String userId)`
    - `Future<void> addUserToSquad(String squadId, String userId)`

### 2. Infrastructure Layer
**SupabaseSquadRepository:**
- Implements `SquadRepository`.
- Uses `SupabaseClient`.
- **Get Squads**: 
    - Query `squads` table. 
    - Join with `user_squads` count if needed.
    - Note: The mapping of `role` happens in the Use Case or Repository by fetching `user_squads` for the current user separately and merging, or using a view/RPC.
- **Get User Squads**:
    - Query `user_squads` joined with `squads` for a specific `userId`.
    - Returns list of `Squad` objects where the user has a role (owner, member, etc.).
- **Get Squad Roles**:
    - Query `user_squads` for the given `userId`.
    - Returns a Map of `squadId` -> `SquadRole`.
- **Create Squad**: Insert into `squads`. 
    - *Limit Check*: Check if user already owns a squad before insertion.
- **Apply to Squad**: 
    - Insert `user_id` and `squad_id` into `user_squads` with role `pending`.
- **Add User to Squad**:
    - Mocked implementation for now.
    - Intended logic: Insert `user_id` and `squad_id` into `user_squads` with role `member`.

### 3. Application Layer
**Use Cases:**
- `GetSquadsUseCase`: 
    - Depends on `SquadRepository`,`UserRepository`.
    - Logic:
        1. Fetch all squads via `repository.getSquads()`.
        2. If user is guest, return squads with `role = none`.
        3. If user is logged in:
            - Fetch user's squads via `repository.getUserSquads(userId)`.
            - Iterate through already fetched squads and assign `role` from the fetched map.
            - Default to `none` if not found in map.
        4. Return modified list of squads.

- `CreateSquadUseCase`: 
    - Validates input.
    - Checks owner limit (1 squad per owner).
    - Calls `repository.createSquad`.

- `ApplyToSquadUseCase`:
    - Depends on `SquadRepository`.
    - Logic:
        - Calls `repository.applyToSquad(squadId, userId)`.

### 4. Presentation Layer
**State Management (Riverpod):**
- `SquadsState`:
    - `isLoading`: bool
    - `squads`: List<Squad>
    - `error`: String?
- `SquadsNotifier` (AsyncNotifier or StateNotifier):
    - `loadSquads()`
    - `createSquad(name, visibility)`
    - `applyToSquad(squadId)`

**UI Components:**
- `SquadListItem`: 
    - Shared widget for displaying a single squad.
    - Props: `Squad` object (now includes `role`), `onTap` callback.
    - **Visibility & Interaction Logic**:
        - **Guest**: Always show lock for private, user icon for public. Click -> "Login required".
        - **Logged-in**:
            - `role == owner/admin/member`: Click -> Enter Squad View.
            - `role == pending`: Show "Pending" status indicator. Click -> "Request sent".
            - `role == invited`: Show "Invited" badge. Click -> Accept/Decline dialog.
            - `role == none`:
                - Public: Click -> Enter Squad View.
                - Private: Show Lock. Click -> "Apply to join".

- `SquadsPage`:
    - Scaffold with AppBar.
    - `ListView` of `SquadListItem`.
    - FAB for "Create Squad" (hidden for guests or shows login prompt).

## Specific Requirements & Logic

### Visibility & Permissions
- **Public Squads**: Visible to all.
- **Private Squads**: Visible in list (with lock icon). Details restricted.
- **Owner Limit**: 1 squad per owner.

### Guest vs User Experience
- **Guest**: Can view list, cannot apply/create.
- **Logged-in User**: Can apply (pending), accept invites, view own squads, create squad (limit 1).

## Dependencies
- `flutter_riverpod`
- `supabase_flutter`
- `go_router`
