# Feature: Squad Settings

## 1. Overview
Implementation of the Squad Settings screen, accessible only to the Squad Owner. This feature allows management of squad details (name, visibility), member roles (promote, demote, remove), and handling of join requests (pending members).

## 2. User Stories
- **US-026 (Settings Access):** As an owner, I want to access settings via a gear icon on the squad details page.
- **US-027 (Pending Notifications):** As an owner, I want to see a badge count of pending requests on the settings icon.
- **US-028 (Settings Management):** As an owner, I want to view members, manage roles, change squad details, or delete the squad.

## 3. Architecture & Design

### 3.1 Domain Layer
**Entities:**
- `SquadMember` (existing) will need to ensure `UserSquadRole` covers: `owner`, `admin`, `member`, `pending`, `declined`.

**Repository Interfaces:**
- `SquadRepository`:
  - `updateSquad(String squadId, {String? name, SquadVisibility? visibility})`
  - `deleteSquad(String squadId)`
- `MembershipRepository`:
  - `updateMemberRole(String squadId, String userId, UserSquadRole newRole)` (Used for promote/demote and decline)
  - `removeMember(String squadId, String userId)` (Used for kicking members)

### 3.2 Application Layer (Use Cases)
1.  **`GetSquadSettingsMembersUseCase`**
    - Fetches members for a squad.
    - Sorts them: Pending > Owner > Admin > Member.
    - Filters out banned/cancelled/declined if any.
2.  **`ModifyMemberRoleUseCase`**
    - Inputs: `squadId`, `userId`, `newRole`.
    - Logic: Validates transitions (e.g., Member -> Admin).
3.  **`RemoveMemberUseCase`**
    - Inputs: `squadId`, `userId`.
    - Logic: Removes a member from the squad (kick).
4.  **`DeclineJoinRequestUseCase`**
    - Inputs: `squadId`, `userId`.
    - Logic: Updates member role to `declined`.
5.  **`ChangeSquadNameUseCase`**
    - Inputs: `squadId`, `newName`.
6.  **`ChangeSquadVisibilityUseCase`**
    - Inputs: `squadId`, `newVisibility`.
7.  **`DeleteSquadUseCase`**
    - Inputs: `squadId`.
8.  **`GenerateInviteLinkUseCase`**
    - Todo/Placeholder implementation.
    - Returns a mock link, validity time.

### 3.3 Presentation Layer
**State Management (Riverpod):**
- **`SquadSettingsNotifier` (AsyncNotifier):**
  - State: `AsyncValue<List<SquadMember>>` (or a composite state with squad details).
  - Methods: `promoteToAdmin`, `demoteToMember`, `removeFromSquad`, `acceptRequest`, `declineRequest`, `updateName`, `updateVisibility`, `deleteSquad`, `regenerateInviteLink`.
  - **Crucial:** All state changes delegate to Use Cases.

- **`SquadDetailsNotifier` (Existing):**
  - Needs to expose `pendingRequestsCount`.
  - This might require a lightweight fetch or deriving from the full member list if already loaded.

**UI Components:**
1.  **`SquadSettingsPage`:**
    - **Header:** Members List.
    - **Member Tile:**
      - Icon, Email, Role Badge (Gold/Orange/Grey).
      - **Actions:**
        - Owner: None.
        - Admin: Downgrade (-> Member), Remove.
        - Member: Upgrade (-> Admin), Remove.
        - Pending: Accept (Check), Decline (X - sets status to declined).
    - **Invite Section:** 
      - Display Container with Link (Mocked).
      - Copy Button (Clipboard interaction).
      - Validity info text (e.g., "Valid for 24h").
      - Regenerate Button.
    - **Danger Zone:**
      - Red border container.
      - Change Name (Input + Save).
      - Change Visibility (Dropdown/Switch).
      - Delete Squad (Button with confirmation).
      - Change Owner (Mock/Disabled).

2.  **`SquadDetailsPage` (Update):**
    - Add `IconButton` (gear) in AppBar actions.
    - Wrap in `Badge` widget showing `pendingCount` > 0.
    - Visibility: `if (currentUser.id == squad.ownerId)`.

## 4. Implementation Plan

### Phase 1: Domain & Infrastructure
- [ ] Update `SquadRepository` interface and Supabase implementation (`update`, `delete`).
- [ ] Update `MembershipRepository` interface and Supabase implementation (`updateRole`, `remove`).
- [ ] Create Use Cases: `ModifyMemberRole`, `RemoveMember`, `DeclineJoinRequest`, `ChangeSquadName`, `ChangeSquadVisibility`, `DeleteSquad`.

### Phase 2: Presentation Logic
- [ ] Create `SquadSettingsNotifier`.
- [ ] Update `SquadDetailsNotifier` to provide `pendingCount`.

### Phase 3: UI Implementation
- [ ] Implement `SquadSettingsPage` layout.
- [ ] Build `MemberTile` with role-based logic for badges and action buttons.
- [ ] Build `InviteSection` with copy/regenerate mock flow.
- [ ] Build `DangerZone` section.
- [ ] Integrate Gear Icon into `SquadDetailsPage`.

## 5. Dependencies & Edge Cases
- **RBAC:** Ensure bam 
- **Self-Action:** Owner cannot remove themselves or change their own role here (except "Change Owner" which is todo).
- **Concurrency:** Optimistic UI updates recommended for role changes.

