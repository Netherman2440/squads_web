# Player Details — Implementation Plan (US-012, US-013, US-014, US-015)

## Overview

Player Details feature extends the Players feature with:
- Detailed player view (name, ranking, delta)
- Ranking history tracking with graph visualization
- Match history (future/mocked)
- Player statistics (future/mocked)
- Manual and automatic ranking updates

---

## User Stories & Requirements

### US-012: Match Result Entry (`prd.md`)
- Save `home_score`, `away_score`, and `score_meta`
- After saving, generate delta affecting ranking of players who played
- Editing results updates the appropriate delta and statistics

### US-013: Manual Ranking Changes
- As admin, I want to manually change a player's ranking
- This updates their current ranking and creates a new ranking history entry

### US-014: Player Details View
- As user, I want to view player details (name, ranking, delta)
- I want to know which matches and tournaments they participated in
- I want access to their statistics

### US-015: Player Profile Editing
- As admin, I want to update player's name and position

---

## Database Schema

### New Table: `ranking_history`

Referenced from `.ai/db_plan.md` section 1.12:

| Column                 | Type        | Constraints                                                 |
| ---------------------- | ----------- | ----------------------------------------------------------- |
| `ranking_history_id`   | UUID        | PK                                                          |
| `player_id`            | UUID        | NOT NULL, FK → `players(player_id)` ON DELETE CASCADE      |
| `match_id`             | UUID        | NULLABLE, FK → `matches(match_id)` ON DELETE SET NULL      |
| `ranking`              | NUMERIC(6,3)| NOT NULL (snapshot of ranking before change)               |
| `change`               | NUMERIC(6,3)| NULLABLE (delta applied to ranking)                         |
| `match_score`          | JSONB       | NULLABLE (format: `{"player": int, "opponent": int}`)      |
| `created_at`           | TIMESTAMPTZ | NOT NULL DEFAULT now()                                      |
| `updated_at`           | TIMESTAMPTZ | NULLABLE (set when result is updated)                       |

**Note:** `match_score` JSONB structure will be defined by the matches feature.

**Constraints:**
- UNIQUE `(player_id, match_id)` WHERE `match_id` IS NOT NULL
- Index on `player_id` for fast history lookups
- Index on `match_id` for match details lookup

**Migration file:** `supabase/migrations/YYYYMMDDHHMMSS_create_ranking_history.sql`

---

## Domain Layer

### 1. New Entity: `RankingHistoryEntry`

**File:** `app/lib/features/players/domain/entities/ranking_history_entry.dart`

```dart
class RankingHistoryEntry {
  final String rankingHistoryId;
  final String playerId;
  final String? matchId;
  final double ranking;
  final double? change;
  final Map<String, dynamic>? matchScore; // JSONB from matches feature
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed property: current ranking after applying change
  double get currentRanking => ranking + (change ?? 0);

  const RankingHistoryEntry({
    required this.rankingHistoryId,
    required this.playerId,
    this.matchId,
    required this.ranking,
    this.change,
    this.matchScore,
    required this.createdAt,
    this.updatedAt,
  });

  factory RankingHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RankingHistoryEntry(
      rankingHistoryId: map['ranking_history_id'] as String,
      playerId: map['player_id'] as String,
      matchId: map['match_id'] as String?,
      ranking: (map['ranking'] as num).toDouble(),
      change: (map['change'] as num?)?.toDouble(),
      matchScore: map['match_score'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ranking_history_id': rankingHistoryId,
      'player_id': playerId,
      'match_id': matchId,
      'ranking': ranking,
      'change': change,
      'match_score': matchScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

**Note:** `MatchScore` entity will be defined in `features/matches` when that feature is implemented. For now, we work with raw JSONB (`Map<String, dynamic>`).

### 2. New Repository: `RankingRepository`

**File:** `app/lib/features/players/domain/repositories/ranking_repository.dart`

```dart
abstract class RankingRepository {
  /// Get all ranking history entries for a specific player, ordered by created_at DESC
  Future<List<RankingHistoryEntry>> getPlayerRankingHistory(String playerId);

  /// Get a specific ranking history entry by match_id
  Future<RankingHistoryEntry?> getRankingHistoryEntryByMatch(
    String matchId,
    String playerId,
  );

  /// Update player ranking (creates new ranking_history entry and updates player.ranking)
  /// If matchId is provided, validates and updates existing entry
  /// If matchId is null, creates manual adjustment entry
  Future<void> updatePlayerRanking({
    required String playerId,
    required double newRanking,
    String? matchId,
  });

  /// Create initial ranking history entry when match is created (change = null)
  Future<RankingHistoryEntry> createMatchRankingEntry({
    required String playerId,
    required String matchId,
    required double currentRanking,
  });
}
```

### 3. Updated Repository: `PlayerRepository`

**File:** `app/lib/features/players/domain/repositories/player_repository.dart`

**Changes:**
- `updatePlayer` method signature change:
  - **REMOVE** `ranking`/`score` parameter
  - Only allow updating `name` and `position`
  - Ranking updates MUST go through `RankingRepository.updatePlayerRanking`

```dart
abstract class PlayerRepository {
  // ... existing methods ...

  /// Update player profile (name, position only)
  /// Ranking changes must use RankingRepository.updatePlayerRanking
  Future<void> updatePlayer({
    required String playerId,
    String? name,
    String? position,
  });
}
```

---

## Infrastructure Layer

### 1. Ranking Repository Implementation

**File:** `app/lib/features/players/infrastructure/repositories/supabase_ranking_repository.dart`

**Key Logic:**

#### `updatePlayerRanking` Method Flow:

```
IF matchId != null:
  1. Fetch existing ranking history entry by (player_id, match_id)
  2. IF not found → throw RankingHistoryNotFoundException
  3. Check if entry can be updated:
     - Query if there exists newer entry with updated_at != null
     - IF exists → throw RankingUpdateConflictException("Cannot update: newer match result exists")
  4. Calculate change = newRanking - entry.ranking
  5. Update ranking_history: SET change = calculated_change, updated_at = now()
  6. Update player.ranking = newRanking

ELSE (matchId == null):
  1. Fetch current player.ranking
  2. Calculate change = newRanking - player.ranking
  3. Create new ranking_history entry:
     - ranking = player.ranking
     - change = calculated_change
     - match_id = null
     - created_at = now()
  4. Update player.ranking = newRanking

Note: Multiple unresolved matches (change = null) are allowed.
      Delta is always added to current player.ranking.
```

### 2. Updated Player Repository Implementation

**File:** `app/lib/features/players/infrastructure/repositories/supabase_player_repository.dart`

**Changes:**
- Rename from `PlayerRepositoryImpl` to `SupabasePlayerRepository`
- Update `updatePlayer` to only accept `name` and `position`
- Remove any ranking-related update logic

---

## Application Layer (Use Cases)

### 1. ✅ GetPlayerDetailsUseCase (Already Implemented)

**File:** `app/lib/features/players/application/usecases/get_player_details_usecase.dart`

- Already exists, fetches player by ID

### 2. GetPlayerRankingHistoryUseCase

**File:** `app/lib/features/players/application/usecases/get_player_ranking_history_usecase.dart`

```dart
class GetPlayerRankingHistoryUseCase {
  final RankingRepository _rankingRepository;

  GetPlayerRankingHistoryUseCase(this._rankingRepository);

  Future<List<RankingHistoryEntry>> execute(String playerId) async {
    return await _rankingRepository.getPlayerRankingHistory(playerId);
  }
}
```

**Future Enhancement:** Add match and team repositories to enrich entries with match details.

### 3. UpdatePlayerNameUseCase

**File:** `app/lib/features/players/application/usecases/update_player_name_usecase.dart`

```dart
class UpdatePlayerNameUseCase {
  final PlayerRepository _playerRepository;

  UpdatePlayerNameUseCase(this._playerRepository);

  Future<void> execute({
    required String playerId,
    required String newName,
  }) async {
    await _playerRepository.updatePlayer(
      playerId: playerId,
      name: newName,
    );
  }
}
```

### 4. UpdatePlayerPositionUseCase

**File:** `app/lib/features/players/application/usecases/update_player_position_usecase.dart`

```dart
class UpdatePlayerPositionUseCase {
  final PlayerRepository _playerRepository;

  UpdatePlayerPositionUseCase(this._playerRepository);

  Future<void> execute({
    required String playerId,
    required String? newPosition,
  }) async {
    await _playerRepository.updatePlayer(
      playerId: playerId,
      position: newPosition,
    );
  }
}
```

### 5. UpdatePlayerRankingUseCase

**File:** `app/lib/features/players/application/usecases/update_player_ranking_usecase.dart`

```dart
class UpdatePlayerRankingUseCase {
  final RankingRepository _rankingRepository;

  UpdatePlayerRankingUseCase(this._rankingRepository);

  Future<void> execute({
    required String playerId,
    required double newRanking,
  }) async {
    // Creates manual adjustment (matchId = null)
    await _rankingRepository.updatePlayerRanking(
      playerId: playerId,
      newRanking: newRanking,
      matchId: null,
    );
  }
}
```

### 6. UpdatePlayerMatchRankingUseCase (TODO - Future)

**File:** `app/lib/features/players/application/usecases/update_player_match_ranking_usecase.dart`

- Will be implemented when match result entry feature is built
- Uses `RankingRepository.updatePlayerRanking` with `matchId` parameter

---

## Presentation Layer

### 1. Player Details Page

**File:** `app/lib/features/players/presentation/pages/player_details_page.dart`

**Layout:**

```
┌─────────────────────────────────────┐
│  [← Back]         Player Details    │
├─────────────────────────────────────┤
│                                     │
│   ┌───────┐                         │
│   │   A   │  Alice Johnson          │
│   └───────┘  Ranking: 1250.50       │
│              ↑ +25.50               │  ← Delta with arrow (green/red)
│                                     │
│   [Edit Name] [Edit Ranking]        │
│                                     │
├─────────────────────────────────────┤
│  Ranking History                    │
│  ┌─────────────────────────────────┐│
│  │     Graph Widget                ││
│  │  (RankingHistoryGraphWidget)    ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│  [ Matches ] [Tournaments] [Stats]  │  ← Navigation tabs
└─────────────────────────────────────┘
```

**Key Features:**
- **NO position display or editing** (per requirements)
- Display name and current ranking
- Show delta with arrow:
  - `difference = player.ranking - player.baseRanking`
  - Use `_ScoreDifference` widget pattern from `players_list_widget.dart` (rename to `_RankingDifference`)
- Edit buttons for name and ranking (admin only)
- Embedded `RankingHistoryGraphWidget`
- Three navigation tabs at bottom

**State Management:**
- Use `ConsumerWidget` or `ConsumerStatefulWidget`
- Providers for:
  - Player details
  - Ranking history
  - Update operations

### 2. Ranking History Graph Widget

**File:** `app/lib/features/players/presentation/widgets/ranking_history_graph_widget.dart`

**Input:** `List<RankingHistoryEntry>` (sorted by `created_at` ASC for display)

**Behavior:**
- Each point on graph = `entry.ranking + (entry.change ?? 0)` = `entry.currentRanking`
- First point starts at `player.baseRanking`
- X-axis: index (0, 1, 2, ...) or date labels
- Y-axis: ranking values with dynamic bounds
- Use `fl_chart` package (similar to legacy implementation)
- Empty state: Display "No ranking changes" centered text

**Reference:** `.legacy/frontend/lib/pages/player_detail_page.dart:578-690`

**Features from legacy:**
- Line chart with dots at each entry
- Dynamic Y-axis bounds calculation (`_getYAxisBounds`)
- Grid lines for readability
- Proper axis labels and intervals

### 3. Edit Dialogs (Reusable)

**Files:**
- `app/lib/features/players/presentation/widgets/edit_player_name_dialog.dart`
- `app/lib/features/players/presentation/widgets/edit_player_ranking_dialog.dart`

Simple dialogs with TextField and validation.

### 4. Navigation Tabs

**File:** `app/lib/features/players/presentation/widgets/player_detail_tabs_widget.dart`

Three navigation buttons:
- **Matches** → `/squads/:squadId/players/:playerId/matches`
- **Tournaments** → `/squads/:squadId/players/:playerId/tournaments`
- **Stats** → `/squads/:squadId/players/:playerId/stats`

**MVP Behavior:** 
- Clicking any tab shows a "TODO" SnackBar
- Routes are defined but pages show placeholder content

### 5. Placeholder Subpages (Future)

**Files (create empty pages for routing):**
- `app/lib/features/players/presentation/pages/player_matches_page.dart`
- `app/lib/features/players/presentation/pages/player_tournaments_page.dart`
- `app/lib/features/players/presentation/pages/player_stats_page.dart`

Each page displays centered text: "Coming soon..."

---

## Integration Points

### A. Match Creation (Draft Feature)
**When:** A new match/draft is finalized

**Action:**
1. For each player in the match:
   ```dart
   await rankingRepository.createMatchRankingEntry(
     playerId: player.playerId,
     matchId: match.matchId,
     currentRanking: player.ranking,
   );
   ```
2. Creates ranking_history entry with `change = null`
3. Entry acts as placeholder until result is entered

### B. Match Result Entry (Future Feature)
**When:** Admin enters match result

**Action:**
1. For each player:
   ```dart
   await rankingRepository.updatePlayerRanking(
     playerId: player.playerId,
     newRanking: calculatedNewRanking,
     matchId: match.matchId,
   );
   ```
2. Updates existing ranking_history entry with calculated delta
3. Updates player.ranking to new value
4. Sets `updated_at` timestamp

---

## Routing

**Add to `app_router.dart`:**

```dart
GoRoute(
  path: '/squads/:squadId/players/:playerId',
  name: 'player-details',
  builder: (context, state) {
    final squadId = state.pathParameters['squadId']!;
    final playerId = state.pathParameters['playerId']!;
    return PlayerDetailsPage(
      squadId: squadId,
      playerId: playerId,
    );
  },
  routes: [
    GoRoute(
      path: 'matches',
      name: 'player-matches',
      builder: (context, state) {
        final squadId = state.pathParameters['squadId']!;
        final playerId = state.pathParameters['playerId']!;
        return PlayerMatchesPage(
          squadId: squadId,
          playerId: playerId,
        );
      },
    ),
    GoRoute(
      path: 'tournaments',
      name: 'player-tournaments',
      builder: (context, state) {
        final squadId = state.pathParameters['squadId']!;
        final playerId = state.pathParameters['playerId']!;
        return PlayerTournamentsPage(
          squadId: squadId,
          playerId: playerId,
        );
      },
    ),
    GoRoute(
      path: 'stats',
      name: 'player-stats',
      builder: (context, state) {
        final squadId = state.pathParameters['squadId']!;
        final playerId = state.pathParameters['playerId']!;
        return PlayerStatsPage(
          squadId: squadId,
          playerId: playerId,
        );
      },
    ),
  ],
),
```

**Navigation:** 
- Tapping player in `PlayersListWidget` → navigate to `/squads/:squadId/players/:playerId`
- Clicking tabs → navigate to respective subpages

---

## Error Handling

### Custom Exceptions

**File:** `app/lib/features/players/domain/exceptions/ranking_exceptions.dart`

```dart
class RankingHistoryNotFoundException implements Exception {
  final String message;
  RankingHistoryNotFoundException(this.message);
}

class RankingUpdateConflictException implements Exception {
  final String message;
  RankingUpdateConflictException(this.message);
}
```

### UI Error Display
- Use `AsyncValue` error handling pattern
- Display errors in `SelectableText.rich` with red color (per coding standards)
- Don't use SnackBars for errors (only for TODO notifications)

---

## Testing Requirements

### Unit Tests

1. **Domain Layer:**
   - `RankingHistoryEntry.currentRanking` computed property
   - `RankingHistoryEntry.fromMap` / `toMap` serialization

2. **Application Layer:**
   - Each use case with happy path and failure scenarios
   - Mock repositories using `mocktail`

3. **Infrastructure Layer:**
   - `SupabaseRankingRepository.updatePlayerRanking`:
     - ✅ Manual adjustment (matchId = null)
     - ✅ Match result update (matchId provided, entry exists)
     - ❌ Match result update (entry not found → exception)
     - ❌ Update conflict (newer entry exists → exception)
   - `SupabasePlayerRepository.updatePlayer`:
     - ✅ Update name only
     - ✅ Update position only
     - ✅ Update both

### Widget Tests

**Files:**
1. `app/test/features/players/presentation/widgets/ranking_history_graph_widget_test.dart`
   - Render with empty list → shows "No ranking changes"
   - Render with entries → displays chart with correct points

2. `app/test/features/players/presentation/pages/player_details_page_test.dart`
   - Displays player info correctly
   - Shows ranking delta with correct arrow direction
   - Edit buttons trigger dialogs

3. `app/test/features/players/presentation/widgets/player_detail_tabs_widget_test.dart`
   - Tapping tabs navigates to correct routes

---

## Dependencies

### Required Packages

Add to `app/pubspec.yaml` if not present:

```yaml
dependencies:
  fl_chart: ^0.69.0  # For line chart visualization

dev_dependencies:
  mocktail: ^1.0.0   # For testing
```

Run: `flutter pub get`

---

## Implementation Checklist

### Phase 1: Database & Domain
- [ ] Create migration: `ranking_history` table with constraints
- [ ] Run `supabase db push` and verify schema
- [ ] Create `RankingHistoryEntry` entity with tests
- [ ] Create `RankingRepository` interface
- [ ] Update `PlayerRepository` interface (remove ranking from update)
- [ ] Create custom exceptions (`ranking_exceptions.dart`)

### Phase 2: Infrastructure
- [ ] Implement `SupabaseRankingRepository` with all methods
- [ ] Update `SupabasePlayerRepository` (rename from `PlayerRepositoryImpl`)
- [ ] Add Riverpod providers for `RankingRepository`
- [ ] Write unit tests for repository implementations

### Phase 3: Application
- [ ] Implement `GetPlayerRankingHistoryUseCase` with tests
- [ ] Implement `UpdatePlayerNameUseCase` with tests
- [ ] Implement `UpdatePlayerPositionUseCase` with tests
- [ ] Implement `UpdatePlayerRankingUseCase` with tests
- [ ] Create Riverpod providers for all use cases

### Phase 4: Presentation - Core
- [ ] Create `PlayerDetailsPage` with basic layout
- [ ] Add delta display with arrow indicator (rename `_ScoreDifference` → `_RankingDifference`)
- [ ] Implement edit name dialog
- [ ] Implement edit ranking dialog
- [ ] Write widget tests for `PlayerDetailsPage`

### Phase 5: Presentation - Graph
- [ ] Create `RankingHistoryGraphWidget`
- [ ] Implement Y-axis bounds calculation
- [ ] Add empty state handling
- [ ] Style chart (colors, grid, labels)
- [ ] Write widget tests for graph widget

### Phase 6: Presentation - Navigation
- [ ] Create placeholder subpages (matches, tournaments, stats)
- [ ] Create `PlayerDetailTabsWidget` with navigation
- [ ] Add TODO SnackBar on tab clicks
- [ ] Add routes to `app_router.dart` (with nested routes)
- [ ] Update `PlayersListWidget` to navigate to details

### Phase 7: Testing & Quality
- [ ] Run `flutter analyze` → fix all issues
- [ ] Run `flutter test` → all tests pass
- [ ] Review test coverage for new code
- [ ] Update this document with any deviations

---

## Future Enhancements (Post-MVP)

1. **Matches Tab:**
   - Show list of matches player participated in
   - Link to match details page
   - Display match scores and date

2. **Tournaments Tab:**
   - List tournaments player participated in
   - Show tournament results and standings

3. **Stats Tab:**
   - Win/loss record
   - Average ranking change
   - Best/worst performance
   - Activity graph (matches over time)

4. **Graph Enhancements:**
   - Click on point → show match details tooltip
   - Date-based X-axis instead of index
   - Toggle between different time ranges (1M, 3M, 1Y, All)
   - Add annotations for significant matches

5. **Position Management:**
   - Add back position display and editing when needed
   - Position history tracking

---

## Notes & Decisions

### Nomenclature: Score → Ranking

**Rationale:** Throughout the codebase, we use "ranking" terminology:
- `player.ranking` (not `player.score`)
- `RankingRepository` (not `ScoreRepository`)
- `RankingHistoryEntry` (not `ScoreHistoryEntry`)
- `baseRanking` (not `baseScore`)

This provides clearer semantics and distinguishes player ranking from match scores.

### Repository Naming: `Supabase*Repository`

**Rationale:** Using `SupabasePlayerRepository` instead of `PlayerRepositoryImpl`:
- Explicitly indicates the concrete implementation (Supabase)
- Makes it easier to add alternative implementations (e.g., `FirebasePlayerRepository`)
- More maintainable when migrating between database providers
- Follows the pattern: `[Technology][Interface]Repository`

### Why Separate `ranking` and `change` Fields?

This design allows us to:
1. Create placeholder entries when match is created (`change = null`)
2. Track historical ranking at time of match
3. Calculate current ranking as `ranking + change`
4. Support multiple pending matches simultaneously
5. Audit trail of all ranking changes

### Why Not Allow Ranking in `PlayerRepository.updatePlayer`?

**Reason:** Ranking changes have complex side effects:
- Must create ranking_history entry
- Must validate against existing matches
- May conflict with concurrent match results

Forcing updates through `RankingRepository` ensures consistency and proper audit trail.

### Handling Multiple Unresolved Matches

**Scenario:** Match A and Match B both created (change = null), then result entered for Match B.

**Behavior:**
- Match B's delta is calculated from current `player.ranking`
- Player ranking is updated
- Match A remains unresolved
- When Match A result is entered later, its delta uses the **then-current** player.ranking

This is intentional and correct: each match result applies to the player's ranking at the time of entry.

### MatchScore Entity Placement

**Decision:** `MatchScore` entity belongs in `features/matches`, not `features/players`.

**Rationale:**
- Match score structure is owned by the matches domain
- Players feature only stores JSONB representation
- When matches feature is implemented, it will define the entity
- Avoids circular dependencies between features

### Navigation: Subpages vs Inline Content

**Decision:** Navigation tabs open separate subpages (`/players/:id/matches`) instead of showing content below.

**Rationale:**
- Better URL structure for deep linking
- Cleaner separation of concerns
- Each subpage can have its own data loading logic
- More scalable for future enhancements
- Follows web best practices

---

## References

- **PRD:** `.ai/prd.md` (US-012, US-013, US-014, US-015)
- **Database Plan:** `.ai/db_plan.md` (section 1.12 for ranking_history)
- **Legacy Implementation:** `.legacy/frontend/lib/pages/player_detail_page.dart:578-690`
- **Players List Widget:** `app/lib/features/players/presentation/widgets/players_list_widget.dart`
- **Existing Player Entity:** `app/lib/features/players/domain/entities/player.dart`

---

**Document Status:** ✅ Ready for Implementation  
**Last Updated:** 2025-12-27  
**Author:** Architecture Team
