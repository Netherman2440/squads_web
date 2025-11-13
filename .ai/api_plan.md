# REST API Plan

> **Context**
> This plan aligns the REST/HTTP contract with the database plan
> (PostgreSQL on Supabase) and the PRD. The concrete implementation
> is intended to run on **Supabase**, using:
> - auto-generated REST (PostgREST) for simple CRUD endpoints,
> - RPC (SQL functions) or Edge Functions for more complex workflows
>   (e.g. drafting, tournaments, scoring),
> while keeping the resource model and payloads described below.
> On the frontend side, this plan is a **contract for the new
> greenfield Flutter UI** (Squads Web) built with Clean Architecture
> and feature-first organization; the legacy Flutter UI is used only
> as UX reference, not as a code base to extend.
> Legend for status: **EXISTING** (implemented today), **NEW**, **Δ CHANGE** (breaking or additive change), **DEPRECATED**.

---

## 1. Resources

| Resource               | DB Table(s)                                                  | Notes                                                                                                                    |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| **Auth & Users**       | `users`                                                      | Email (CITEXT) unique, optional username.                                                                                |
| **Squads**             | `squads`, `user_squads`                                      | Visibility enum (`public`/`private`), per‑squad membership and roles (`owner`, `admin`, `member`, `invited`, `pending`). |
| **Players**            | `players`, `score_history`                                   | Per‑squad roster. Base/current rating numeric (0–100 range in API). CITEXT unique name per squad.                        |
| **Drafts (ephemeral)** | — (compute)                                                  | Deterministic proposals given player set (limit 16).                                                                     |
| **Matches**            | `matches`, `teams`, `team_players`                           | `played_at`, `result_type`, `score (home,away)`, `score_meta`. Snapshot teams + rosters.                                 |
| **Tournaments**        | `tournaments`, `tournament_teams`, `tournament_team_players` | Tournament team identities and rosters; matches created within tournaments.                                              |
| **Score History**      | `score_history`                                              | One delta per (player, match) + manual adjustments (with `match_id` NULL).                                               |
| **Stats & Reports**    | (views/queries)                                              | Derived from core tables.                                                                                                |

**Enumerations surfaced by API** (mirrored from DB):
`squad_visibility = public|private`, `sport_type = football`, `side = home|away`,
`match_result_type = regular|penalties|walkover|cancelled`,
`match_approval_status = pending|approved`,
`user_squad_role = owner|admin|member|invited|pending`,
`tournament_status = draft|active|completed|archived`.

---

## 2. Endpoints

> **Conventions**
>
> * Base path: conceptually `/api/v1` in this document; in Supabase
>   this typically maps to `/rest/v1` (tables/views) and `/rest/v1/rpc`
>   (RPC functions), or Edge Function URLs.
> * Auth: Supabase JWT (access token) carried as HTTP Bearer token
> * Pagination: `page` (default 1), `page_size` (default 20, max 100). Responses include `{ "items": [...], "page": 1, "page_size": 20, "total": 123 }`.
> * Sorting: `sort` (comma separated, use `-` for desc, e.g. `sort=-played_at,name`).
> * Filtering: resource-specific via query parameters.
> * Idempotency (recommended for POST that create): optional `Idempotency-Key` header; if repeated, return same resource.

### 2.1 Auth & Users

#### POST `/auth/register` — **EXISTING**

Create a user (MVP email+password; username optional).

* **Request** `application/json`

  ```json
  { "email": "user@example.com", "password": "secret", "username": "nick" }
  ```
* **Response 200**

  ```json
  { "access_token": "...", "refresh_token": "...", "token_type": "bearer", "user": { "user_id":"...", "email":"...", "username":"...", "created_at":"..." } }
  ```
* **Errors**: `409` (email/username exists), `422`.

> **Δ CHANGE**: add `email` to request/response (current spec only has `username/password`). Enforce CITEXT uniqueness.

#### POST `/auth/login` — **EXISTING**

* **Δ CHANGE**: include `refresh_token` in success payload (PRD requires refresh). Keep current form-urlencoded support, but respond with both tokens.

#### POST `/auth/guest` — **EXISTING**

Issue guest token with limited scope. Guests **cannot** mutate.

#### POST `/auth/refresh` — **NEW**

Exchange refresh token for new access token.

* **Request**

  ```json
  { "refresh_token": "..." }
  ```
* **Response 200**

  ```json
  { "access_token": "...", "token_type": "bearer" }
  ```
* **Errors**: `401` (invalid/expired), `422`.

#### POST `/auth/logout` — **NEW**

Invalidate refresh token (remove from secure storage).

* **Response** `204`.

#### GET `/users/me` — **NEW**

Return current user profile and memberships.

* **Response 200**

  ```json
  {
    "user_id":"...", "email":"...", "username":"...", "created_at":"...",
    "owned_squads":[{...}],
    "memberships":[{ "squad_id":"...", "role":"admin", "joined_at":"..." }]
  }
  ```

---

### 2.2 Squads

#### GET `/squads` — **EXISTING**

List squads visible to requester.

* **Query**: `visibility`, `sport_type`, `owner_id`, `member_of=true|false`, `search`, `page`, `page_size`, `sort` (`created_at`, `name`).
* **Response 200**

  ```json
  { "items":[
      {"squad_id":"...","name":"...","visibility":"public","sport_type":"football","players_count":12,"owner_id":"...","created_at":"..."}
    ],
    "page":1,"page_size":20,"total":42
  }
  ```

> **Δ CHANGE**: add `visibility` and `sport_type` fields to responses and filters.

#### POST `/squads` — **EXISTING → Δ CHANGE**

Create a squad (non-guest only, limit 1 per owner per PRD).

* **Request**

  ```json
  { "name":"My Squad", "visibility":"public", "sport_type":"football" }
  ```
* **Response 201**

  ```json
  { "squad_id":"...", "name":"...", "visibility":"public", "sport_type":"football",
    "owner_id":"...", "players_count":0, "created_at":"..." }
  ```
* **Errors**: `403` (guest), `409` (owner already has a squad), `422`.

#### GET `/squads/{squad_id}` — **EXISTING → Δ CHANGE**

* **Response 200**: include `visibility`, `sport_type`, `members_count`, `stats`.
* **Errors**: `404` (not visible).

#### PUT `/squads/{squad_id}` — **NEW**

Owner/Admin can update `name`, `visibility`, `sport_type`.

* **Request**

  ```json
  { "name":"...", "visibility":"private", "sport_type":"football" }
  ```
* **Response 200**: updated squad.

#### DELETE `/squads/{squad_id}` — **EXISTING**

---

### 2.3 Squad Memberships & Invites

> Backed by `user_squads` with `role` including invite states. Email-based invitations to non-users are out-of-scope for MVP (no table), but inviting an existing user is supported.

#### GET `/squads/{squad_id}/members` — **NEW**

List members with roles (Owner/Admin only).

* **Response 200**

  ```json
  { "items":[ { "user_id":"...","role":"member","joined_at":"..." } ],
    "page":1,"page_size":20,"total":3 }
  ```

#### POST `/squads/{squad_id}/members` — **NEW**

Invite/add an existing user by `user_id`.

* **Request**

  ```json
  { "user_id":"...", "role":"member", "mode":"invite" }  // mode: invite|add
  ```
* **Response 201**

  ```json
  { "user_id":"...","role":"invited","created_at":"..." }
  ```
* **Errors**: `409` (already member/invited), `403` (not Owner/Admin).

#### PATCH `/squads/{squad_id}/members/{user_id}` — **NEW**

* Change role (Owner/Admin): `{ "role":"admin" }`.
* Accept/decline invitation (self): `{ "action":"accept" }` or `{ "action":"decline" }`.

  * Accept transitions `invited|pending → member`.
* **Response 200**: updated membership.

#### DELETE `/squads/{squad_id}/members/{user_id}` — **NEW**

Remove a member (Owner/Admin) or leave squad (self). `204`.

---

### 2.4 Players

#### GET `/squads/{squad_id}/players` — **EXISTING**

* **Query**: `search`, `position`, `min_score`, `max_score`, `page`, `page_size`, `sort` (`created_at`, `name`, `score`).
* **Response 200**

  ```json
  { "items":[
      {"player_id":"...","name":"Ana","position":"midfielder","score":72.5,"base_score":70,"matches_played":12,"created_at":"..."}
    ],
    "page":1,"page_size":20,"total":50
  }
  ```

> **Δ CHANGE**: treat name uniqueness case‑insensitively (CITEXT). On conflict, return `409` with a helpful error.

#### POST `/squads/{squad_id}/players` — **EXISTING**

* **Request**

  ```json
  { "name":"Ana", "base_score":70, "position":"midfielder" }
  ```
* **Response 201**: player row with computed `score` (defaults to base).
* **Errors**: `409` (duplicate name), `403` (not Owner/Admin), `422`.

#### GET `/squads/{squad_id}/players/{player_id}` — **EXISTING**

* **Response 200** includes `stats` (keep current) and add `score_history` if `?include=history`.

#### PUT `/squads/{squad_id}/players/{player_id}` — **EXISTING**

* **Δ CHANGE**: allow updating `name`,  `position`; `score` is **derived** and read-only. If provided, ignore or `422`.

#### DELETE `/squads/{squad_id}/players/{player_id}` — **EXISTING**


---

### 2.5 Drafts

#### POST `/squads/{squad_id}/matches/draw` — **EXISTING**

Generate balanced team proposals for a set of players.

* **Request**

  ```json
  { "players_ids":[ "...", "...", "..." ] }
  ```
* **Response 200**

  ```json
  { "drafts":[
      { "team_a":[{...player...}], "team_b":[{...player...}] }
    ] }
  ```
* **Errors**: `403` (guest).

> Based on existing implementation in `/squads/{squad_id}/matches/draw` endpoint.

---

### 2.6 Matches (incl. Teams & Rosters)

#### GET `/squads/{squad_id}/matches` — **EXISTING → Δ CHANGE**

* **Query**:  `tournament_id`, , `score_type`, `page`, `page_size`, `sort=-created_at`.
* **Response 200**

  ```json
  { "items":[
      { "match_id":"...","squad_id":"...","played_at":"...",
        "home_score":2, "away_score":1, "score_meta":{ "penalties": { "home":5, "away":4 } }, "score_type":"regular", }
    ],
    "page":1,"page_size":20,"total":12
  }
  ```

>

#### POST `/squads/{squad_id}/matches` — **EXISTING → Δ CHANGE**

Create a match from two rosters (snapshot).

* **Request**

  ```json
  {
    "home": { "player_ids":[ "...", "..." ], "name":"Reds", "color":"#a00" },
    "away": { "player_ids":[ "...", "..." ], "name":"Blues", "color":"#00a" },
    "played_at":"2025-09-01T18:00:00Z",
    "tournament_id": null
  }
  ```
* **Response 201**

  ```json
  {
    "match_id":"...","squad_id":"...","created_at":"...",
    "home": { "team_id":"...","side":"home","name":"Reds","color":"#a00","players":[...] },
    "away": { "team_id":"...","side":"away","name":"Blues","color":"#00a","players":[...] },
    "score": null, "result_type": null, "approval_status":"pending"
  }
  ```
* **Errors**: `422` (duplicate player in both teams), `409` (player not in squad), `403` (Owner/Admin only).

> **Δ CHANGE**: deprecate `team_a/team_b` and `TeamDetailResponse.score` (team-level score). Use `side: home|away` and `matches.home_score` and `matches.away_score` as a pair (`[home, away]`). This mirrors DB where `teams.score` was removed.

#### GET `/squads/{squad_id}/matches/{match_id}` — **EXISTING → Δ CHANGE**

Return full match including team snapshots and roster.

* **Response 200**

  ```json
  {
    "match_id":"...","squad_id":"...","played_at":"...","created_at":"...",
    "home":{ "team_id":"...","side":"home","name":"...","color":"...","players":[...] },
    "away":{ "team_id":"...","side":"away","name":"...","color":"...","players":[...] },
    "score": [2,1], "score_type":"regular",
    "score_meta": { "penalties": { "home":5, "away":4 } },
  }
  ```

#### PATCH `/squads/{squad_id}/matches/{match_id}/lineup` — **NEW**

Update rosters **only if no approved score** exists.

* **Request**

  ```json
  { "home": { "player_ids":[...] }, "away": { "player_ids":[...] } }
  ```
* **Response 200**: updated teams.
* **Errors**: `409` (locked after approval), `422` (player in both sides).

#### DELETE `/squads/{squad_id}/matches/{match_id}` — **EXISTING**

---

### 2.7 Match Scoring & Approval

#### POST `/squads/{squad_id}/matches/{match_id}/score` — **NEW**

Set or update score and result metadata.

* Admin: sets `approval_status="pending"`.

* Owner: may set `?auto_approve=true` to approve immediately.

* **Request**

  ```json
  { "score":[2,1], "result_type":"regular", "score_meta": {} }
  ```

* **Response 200**

  ```json
  { "match_id":"...","score":[2,1],"result_type":"regular","score_meta":{},
    "approval_status":"pending","submitted_by":"...","submitted_at":"..." }
  ```

* **Side effects**: produce/adjust `score_history` deltas for players who played.

---

### 2.8 Tournaments

#### GET `/squads/{squad_id}/tournaments` — **NEW**

* **Query**: `status`, `page`, `page_size`, `sort=-created_at`.
* **Response 200**

  ```json
  { "items":[
      { "tournament_id":"...","squad_id":"...","name":"Autumn Cup",
        "status":"active","created_at":"..." }
    ], "page":1,"page_size":20,"total":2 }
  ```

#### POST `/squads/{squad_id}/tournaments/draw` — **NEW**

Create tournament in `active` status.

* **Request**

  ```json
  { "name":"Autumn Cup",
  "players":["...", "...", "..."] 
  "teams_count": 3
  }
  ```
* **Response 201**: tournament with `status:"draft"`.

#### POST `/squads/{squad_id}/tournaments` — **NEW**

Create tournament in `active` status.

* **Request**

  ```json
  { "name":"Autumn Cup",
  "teams":[ { "name":"Reds","color":"#a00","players":[...]} ],
  }
  ```
* **Response 201**: tournament with `status:"active"`.

#### GET `/squads/{squad_id}/tournaments/{tournament_id}` — **NEW**

Return tournament, teams, roster assignments, matches.

* **Response 200**

  ```json
  {
    "tournament_id":"...","squad_id":"...","name":"...","status":"active","created_at":"...",
    "teams":[ { "tournament_team_id":"...","name":"Reds","color":"#a00","players":[...]} ],
    "matches":[ ... ],
    "stats": { "table":[ {"team":"Reds","played":3,"wins":2,"draws":0,"losses":1,"gf":6,"ga":4,"gd":2,"points":6} ] }
  }
  ```

#### PATCH `/squads/{squad_id}/tournaments/{tournament_id}` — **NEW**

Update `name` or `status` (`draft→active→completed→archived`).


#### PATCH `/squads/{squad_id}/tournaments/{tournament_id}/teams` — **NEW**

Edit name/color; swap players across teams (effective for future matches).

* **Request**

    ```json
    { "teams":[ { "tournament_team_id":"...","name":"Reds","color":"#a00","players":[...]} ] }
  ```

#### GET `/squads/{squad_id}/tournaments/{tournament_id}/matches` — **NEW**

List tournament matches.

#### POST `/squads/{squad_id}/tournaments/{tournament_id}/matches` — **NEW**

Create a match between two tournament teams.

* **Request**

  ```json
  { "home_tournament_team_id":"...", "away_tournament_team_id":"...", "played_at":"..." }
  ```
* **Response 201**: created `match` (with team snapshots; rosters default from tournament teams at creation time).

#### GET `/squads/{squad_id}/tournaments/{tournament_id}/table` — **NEW**

Simple classification (W/D/L, goal diff, points).

* **Response 200**

  ```json
  { "table":[ {"tournament_team_id":"...","team_name":"Reds","played":3,"wins":2,"draws":0,"losses":1,"gf":6,"ga":4,"gd":2,"points":6} ] }
  ```

> **Δ CHANGE needed in DB** to fully support tournaments per plan:
>
> * Add `status` to `tournaments` (enum).
> * Add optional `tournament_team_id` to `teams` (nullable reference snapshot).
> * Ensure `UNIQUE (tournament_id, tournament_team_id)` (support existing composite FK from `tournament_team_players`).

---

### 2.10 Audit Logs

#### GET `/audit-logs` — **NEW (Owner/Admin; Admins see all, Members see own)**

* **Query**: `entity_type`, `entity_id`, `action`, `actor_user_id`, `from`, `to`, `page`, `page_size`.
* **Response 200**

  ```json
  { "items":[
      { "audit_id":"...","actor_user_id":"...","action":"match.result.update",
        "entity_type":"match","entity_id":"...","payload":{...},"ip":"1.2.3.4","user_agent":"...","created_at":"..." }
    ], "page":1,"page_size":50,"total":123 }
  ```

> Automatically record: `squad.create`, `invite.send`, `member.role.update`, `match.create`, `match.result.update`, `match.approve`, `tournament.create`, etc.

---

### 2.11 Stats & Reports

#### GET `/squads/{squad_id}/stats` — **NEW** optional for MVP

Returns the existing `SquadStats` plus optional period filters.

* **Query**: `from`, `to`.
* **Response 200**

  ```json
  {
    "squad_id":"...","created_at":"...","total_players":24,
    "total_matches":120,"total_goals":370,"avg_player_score":65.4,
    "avg_goals_per_match":3.1,"avg_score":[1.6,1.5]
  }
  ```

#### GET `/squads/{squad_id}/metrics/ops` — **NEW** (US‑020) optional for MVP

Operational metrics (matches/week, etc.).

* **Query**: `granularity=day|week|month`, `from`, `to`.
* **Response 200**

  ```json
  { "series":[ { "bucket":"2025-W35","matches":7 } ] }
  ```

---

### 2.12 Health & Misc

#### GET `/health` — **NEW**

Liveness probe. `200 { "status":"ok" }`.

#### GET `/version` — **NEW**

API version and git commit. `200 { "version":"v1.0.0","commit":"..." }`.

---

## 3. Authentication and Authorization

* **Mechanism**: Supabase JWT (HS256) access tokens (optionally
  complemented by refresh tokens handled by Supabase Auth).
* **Scopes / Claims**:

  * `sub` (user_id), `is_guest` (bool), `exp`, optional `scopes` (e.g., `squads:read`, `squads:write`, `matches:approve`).
* **RBAC Rules** (primarily enforced via Supabase RLS policies;
  some additional checks may live in RPC/Edge Functions):

  * Guest: read-only on public squads; cannot POST/PUT/PATCH/DELETE.
  * Member: read private squad they belong to.
  * Admin: manage players, create matches, submit scores.
  * Owner: all admin rights + approve results, manage roles, delete squad.
* **Visibility**:

  * `squads.visibility="public"` are readable by anyone (including guest).
  * Private squads require membership.
* **Approval Workflow**:

  * `POST /matches/{id}/score` by Admin → `approval_status="pending"`.
  * Owner approves via `POST /matches/{id}/approve` → `approval_status="approved"`.
* **Rate limiting** (recommended gateway/nginx): e.g., 100 req/min per IP; stronger for guest.
* **Idempotency**: Honor `Idempotency-Key` on POST for match/tournament creation.
* **Audit**: Log sensitive actions to `audit_logs`.

---

## 4. Validation and Business Logic

### 4.1 Squads

* **Create**

  * `name`: non-empty (1–100 chars).
  * `visibility`: enum (`public|private`), default `public`.
  * `sport_type`: enum (`football`), default `football`.
  * **Owner limit**: 1 squad per owner → `409` if exceeded (PRD).
* **Update**

  * Only Owner/Admin.
* **Read**

  * Private requires membership; public is open (guest allowed).

### 4.2 Memberships

* **Invite/Add**

  * Only Owner/Admin.
  * If user already member or invited → `409`.
  * `role` must be one of `admin|member` when adding; invite sets role to `invited`.
* **Accept/Decline**

  * Only invited user can accept/decline.
  * Transition: `invited|pending → member`.
* **Remove/Leave**

  * Owner/Admin can remove others; any user can leave self (not if Owner and last Owner).

### 4.3 Players

* **Create/Update**

  * `name` unique per squad **case-insensitive** (CITEXT). On conflict: `409` with `{ "code":"player_name_conflict" }`.
  * `base_score` integer [0..100]; server maps to numeric(6,3).
  * `position` enumeration; store as text.
* **Delete**

  * Allowed unless referenced in historical match snapshots? (DB ON DELETE RESTRICT in `team_players` for history preservation). API should prevent delete if player is in any match roster; suggest `409 "player_has_history"`.

### 4.4 Drafts

* **Generate**

  * Up to 16 players; otherwise `422` with `{ "code":"draft_limit_exceeded" }`.
  * Deterministic: include `seed` (server timestamp + sorted ids) in response, optional `draft_token` echo to create matches.

### 4.5 Matches & Rosters

* **Create**

  * Each `player_id` must belong to the squad; duplicates across sides forbidden (`422`).
  * Create two `teams` rows with `side=home|away`, names/colors optional.
  * Create `team_players` rows; UNIQUE `(match_id, player_id)` ensures no player in both sides.
  * Set `approval_status="pending"`.
* **Lineup Update**

  * Allowed only when `approval_status != "approved"`.
  * Enforce uniqueness constraints as above.

### 4.6 Scoring & Approval

* **Submit Score**

  * `score`: pair `[home, away]` integers ≥0.
  * `result_type`: enum; if `penalties`, include `score_meta.penalties = {home, away}`.
  * On update, adjust `score_history` deltas idempotently (unique `(player_id, match_id)`).
* **Approve/Revoke**

  * Owner only.
  * On approve: set `approved_by`, `approved_at`, “lock” rosters; subsequent lineup changes forbidden (`409`).
  * On revoke: unlock for correction.

### 4.7 Tournaments

* **Create**

  * `status="draft"`.
* **Teams**

  * Accept draft to create `tournament_teams`; assign `tournament_team_players`.
  * Enforce UNIQUE `(tournament_id, player_id)` across all tournament teams → `409 "player_already_assigned"`.
  * Team edits affect future matches; snapshots at match creation persist history.
* **Matches**

  * Create match bound to tournament; snapshot rosters from tournament teams at creation time.
* **Table**

  * Computation: 3 points win, 1 draw, 0 loss; simple tie-breaks optional per PRD (can be omitted in MVP).

### 4.8 Score History (Manual)

* **Create**

  * `delta` numeric (±), apply to latest rating; compute `previous_rating` and `new_rating`.
  * Manual adjustments set `match_id = null`.

### 4.9 Audit

* **Coverage**

  * Create entries for: squad create/update/delete; invite send/accept/decline; role change; player CRUD; match create; lineup change; score submit/update; approve/revoke; tournament create/accept draft/edit teams.
* **Retention**

  * Keep indefinitely for MVP.

### 4.10 Performance, Index, and Query Patterns

* Use `matches_squad_played_at_idx (squad_id, played_at DESC)` to power `/matches` listing defaults (`sort=-played_at`).
* Use `score_history_player_time_idx (player_id, created_at DESC)` for score history endpoints.
* Use `players(squad_id)` and unique `(squad_id, name)` for fast player list & uniqueness.
* Use unique `(match_id, player_id)` and `(tournament_id, player_id)` to enforce roster constraints server-side and avoid heavy application logic.

---

### 4.11 Compatibility & Required Changes vs. Current API

1. **Squads**

   * **Δ** `POST /squads`: request must accept `visibility` and `sport_type`.
   * **Δ** `GET /squads` & `GET /squads/{id}` responses include `visibility`, `sport_type`.
   * **NEW** `PUT /squads/{id}`.

2. **Auth**

   * **Δ** `POST /auth/register` & `/auth/login`: include `email` and return `refresh_token`.
   * **NEW** `/auth/refresh`, `/auth/logout`, `/users/me`.

3. **Players**

   * **Δ** Uniqueness is case-insensitive; conflict returns `409` (not `422`).
   * **Δ** `PUT /players/{id}`: `score` field is read-only (remove from payload or ignore).

4. **Drafts**

   * **NEW** `/squads/{id}/drafts`.
   * **DEPRECATED** `/matches/draw` (keep alias for a while).
   * **Δ** Rename `team_a`/`team_b` → `home`/`away` in payloads and responses.

5. **Matches**

   * **Δ** Use `played_at` in list and detail (keep `created_at` in detail).
   * **Δ** `TeamDetailResponse.score` **removed** (score lives at match level as `[home, away]`).
   * **Δ** Include `result_type`, `score_meta`, `approval_status`, `approved_by/at` in detail.
   * **NEW** `/matches/{id}/lineup` (PATCH), `/matches/{id}/score` (POST), `/matches/{id}/approve` (POST/DELETE).

6. **Tournaments**

   * **NEW** full set under `/tournaments` with draft/accept/edit/fixtures/table.

7. **Score History**

   * **NEW** read endpoints per player and match; **NEW** manual adjustments endpoint.

8. **Audit Logs**

   * **NEW** `/audit-logs` (read-only).

9. **Schemas**

   * **Δ** Standardize score pair as two-element array `[home, away]`.
   * **Δ** Add enums (`visibility`, `result_type`, `approval_status`, `side`).

---

**This plan provides the full set of resources and endpoints required by the PRD, reconciles them with the database design, and annotates the exact deltas needed to align the current API with the target model.**
