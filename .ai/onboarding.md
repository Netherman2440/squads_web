# Project Onboarding: Squads

## Welcome

Welcome to the Squads project! Squads is a lightweight app for creating and browsing sports team squads with a FastAPI backend and a Flutter frontend. It provides squad, player, and match management, including balanced team drafting and player statistics. The original Flutter frontend (in the legacy monorepo) is now treated as **legacy UI** and used only as UX inspiration.

## Project Overview & Structure

The core functionality revolves around managing squads, players, and matches, generating balanced team drafts, and surfacing statistics. The original project is organized as a monorepo with a production-ready FastAPI backend and an MVP Flutter frontend (legacy UI). A new Squads Web frontend is being rebuilt **from scratch** in Flutter using Clean Architecture and feature-first organization; the legacy UI serves only as a UX reference, not as a code base to extend.

## Core Modules

### `frontend/lib/pages`

- **Role:** Main application screens for authentication, squad browsing, player details, matches, and drafting.
- **Key Files/Areas:**
  - Pages: `frontend/lib/pages/squad_page.dart`, `frontend/lib/pages/player_detail_page.dart`, `frontend/lib/pages/match_page.dart`, `frontend/lib/pages/squad_list_page.dart`, `frontend/lib/pages/draft_page.dart`
  - Navigation/Flows: `frontend/lib/pages/match_history_page.dart`, `frontend/lib/pages/create_match_page.dart`, `frontend/lib/pages/players_page.dart`, `frontend/lib/pages/auth_page.dart`
- **Top Contributed Files:** `frontend/lib/pages/squad_page.dart`, `frontend/lib/pages/player_detail_page.dart`, `frontend/lib/pages/match_page.dart`
- **Recent Focus:** Significant UI work around the squad view, player detail stats visualization, and match workflows.

### `backend/app/services`

- **Role:** Business logic for squads, players, matches, teams, stats, user management, and team drawing.
- **Key Files/Areas:**
  - Matches & Teams: `backend/app/services/match_service.py`, `backend/app/services/team_service.py`, `backend/app/services/draw_teams_service.py`
  - Players & Squads: `backend/app/services/player_service.py`, `backend/app/services/squad_service.py`
  - Stats & Users: `backend/app/services/stat_service.py`, `backend/app/services/user_service.py`
- **Top Contributed Files:** `backend/app/services/match_service.py`, `backend/app/services/player_service.py`, `backend/app/services/stat_service.py`
- **Recent Focus:** Match lifecycle and scoring updates (score history, validations), player updates, and stats aggregation. Balanced team drafting refined via `draw_teams_service.py`.

### `backend/app/entities`

- **Role:** Domain data structures decoupled from ORM for clean responses and internal transformations.
- **Key Files/Areas:** `backend/app/entities/player_data.py`, `backend/app/entities/match_data.py`, `backend/app/entities/draft_data.py`, `backend/app/entities/stats_data.py`, `backend/app/entities/squad_data.py`
- **Top Contributed Files:** Not listed in top files; used broadly across services and routes.
- **Recent Focus:** Supports richer match and player stats returned by services and routes.

### `backend/tests/integration`

- **Role:** Backend integration tests validating services and routes.
- **Key Files/Areas:** `backend/tests/integration/test_squads_routes.py`, `backend/tests/integration/test_match_service.py`, `backend/tests/integration/test_player_service.py`, `backend/tests/integration/test_team_service.py`, `backend/tests/integration/test_user_service.py`, `backend/tests/integration/test_draw_team_service.py`, `backend/tests/integration/test_auth_routes.py`
- **Top Contributed Files:** The above integration test files (module shows high activity).
- **Recent Focus:** Ensuring correctness of match updates, drafting, and auth-protected squad/player flows.

### `backend/app/schemas`

- **Role:** Pydantic models for request/response payloads.
- **Key Files/Areas:** `backend/app/schemas/squad_schemas.py`, `backend/app/schemas/player_schemas.py`, `backend/app/schemas/match_schemas.py`, `backend/app/schemas/draft_schemas.py`, `backend/app/schemas/stats_schemas.py`, `backend/app/schemas/auth_schemas.py`
- **Top Contributed Files:** Not explicitly in top files; updated alongside services/routes.
- **Recent Focus:** Evolving with match, player, and stats responses.

### `frontend/lib/widgets`

- **Role:** Reusable UI components for players, matches, and stats.
- **Key Files/Areas:** `frontend/lib/widgets/stats_carousel.dart`, `frontend/lib/widgets/player_widget.dart`, `frontend/lib/widgets/players_list_widget.dart`, `frontend/lib/widgets/match_widget.dart`, `frontend/lib/widgets/player_stat_widget.dart`, `frontend/lib/widgets/player_h2h_widget.dart`
- **Top Contributed Files:** Not explicitly listed; carousel and stats widgets heavily used by pages.
- **Recent Focus:** Displaying player stats, H2H info, and match summaries.

### `backend/app/db` (database layer)

- **Role:** Database connectivity and persistence. Note: This module appears in activity stats but the repository exposes it via `backend/app/database.py` and ORM models under `backend/app/models/`.
- **Key Files/Areas:** `backend/app/database.py`, `backend/app/models/*.py` (e.g., `player.py`, `match.py`, `squad.py`, `score_history.py`, `team.py`, `team_player.py`, `tournament.py`, `user.py`, `user_squad.py`)
- **Top Contributed Files:** Not individually in top files; core to service operations.
- **Recent Focus:** Supports score history and team/match relationships relied upon by services.

### `frontend/lib/services`

- **Role:** Client-side HTTP services and token management.
- **Key Files/Areas:** `frontend/lib/services/auth_service.dart`, `frontend/lib/services/squad_service.dart`, `frontend/lib/services/player_service.dart`, `frontend/lib/services/match_service.dart`, `frontend/lib/services/message_service.dart`
- **Top Contributed Files:** `frontend/lib/services/auth_service.dart`
- **Recent Focus:** Token propagation to services and integration with backend auth endpoints.

### `frontend/lib/models`

- **Role:** Dart data models mirrored to backend responses.
- **Key Files/Areas:** `frontend/lib/models/player.dart`, `frontend/lib/models/match.dart`, `frontend/lib/models/squad.dart`, `frontend/lib/models/draft.dart`, `frontend/lib/models/user.dart`, `frontend/lib/models/carousel_type.dart`, `frontend/lib/models/stat_type_config.dart`, `frontend/lib/models/user_role.dart`
- **Top Contributed Files:** Not explicitly listed; updated to support evolving responses.
- **Recent Focus:** Support for stats carousel and match/player structures.

### `backend/app/models`

- **Role:** SQLAlchemy ORM definitions for domain entities.
- **Key Files/Areas:** `backend/app/models/player.py`, `backend/app/models/match.py`, `backend/app/models/score_history.py`, `backend/app/models/squad.py`, `backend/app/models/team.py`, `backend/app/models/team_player.py`, `backend/app/models/tournament.py`, `backend/app/models/user.py`, `backend/app/models/user_squad.py`
- **Top Contributed Files:** Not explicitly listed; foundational for persistence and relations.
- **Recent Focus:** Relations enabling score history and team/match composition.

## Key Contributors

- **Netherman2440 (94918888+Netherman2440@users.noreply.github.com):** Broad contributions across backend services, routes, and frontend pages; likely primary maintainer.
- **zajacignacy@gmail.com:** Significant contributions; touches both backend and frontend modules.

## Overall Takeaways & Recent Focus

1. **Backend match and scoring logic:** Heavy iteration in `match_service.py` and related services around score history, validation of updates, and team/player updates.
2. **Feature Development:** Squad and player flows are actively built out end-to-end (routes → services → schemas → frontend pages and widgets).
3. **Statistics enrichment:** `stat_service.py` builds rich player and squad metrics (win/loss streaks, H2H, teammates), surfaced in frontend widgets.
4. **UI/UX Refinement:** `squad_page.dart` and `player_detail_page.dart` saw frequent changes to improve data presentation and interactivity.
5. **Auth integration:** Active work on `auth_service.dart` and backend `auth` routes to support login/register/guest flows and token propagation.

## Potential Complexity/Areas to Note

- **Score history and ranking recalculation:** Player score updates depend on match order and deltas; see `match_service.py` and `player_service.py` for rules and clamping.
- **Balanced team drafting:** Non-trivial team generation in `draw_teams_service.py` with sorting/heuristics for even matchups.
- **Stats computation:** `stat_service.py` traverses matches and teammates; performance and circular dependency handling (lazy imports) require care.

## Questions for the Team

1. What is the canonical formula and business rules for score updates and streak calculations (any planned changes)?
2. Should match result updates be blocked if older matches lack results (current validation), and how do we handle backfills?
3. What is the intended guest user capability scope across endpoints (read-only lists vs. detail access/modifications)?
4. How are environment-specific configs intended to be managed across backend (`.env`) and frontend (`.env.*` via `AppConfig`)?
5. Are there established patterns for adding new endpoints (routes/schemas/tests) and aligning frontend models/services?
6. What is the CI/CD plan (README mentions manual deploys); any lint/test gating planned for PRs?
7. Is there an issue triage/release cadence documented anywhere (labels, milestones, ownership)?

## Next Steps

1. **Set up environment:** Install Python 3.11+, Docker Desktop, and Flutter SDK; configure local `.env`.
2. **Run backend locally:** Use Docker Compose or Uvicorn; exercise auth, squads, players, and matches endpoints via Swagger.
3. **Explore active modules:** Read `backend/app/services/match_service.py` and `stat_service.py`, and `frontend/lib/pages/squad_page.dart` and `player_detail_page.dart` to trace flows.
4. **Run tests:** Execute `pytest` under `backend/` and try `flutter analyze`/`flutter test` in `frontend/`.
5. **Review repo activity:** Browse recent commits/PRs touching `routes/squads.py` and `frontend/lib/pages/*` for context.

## Development Environment Setup

1. **Prerequisites:** Python 3.11+, Docker Desktop, PostgreSQL (if running locally without Docker), Flutter SDK (plus Java 17+/Android SDK 30+ for Android, Visual Studio 2022 with C++ for Windows builds).
2. **Dependency Installation:**
   - Backend: `cd backend && pip install --upgrade pip && pip install -r requirements.txt`
   - Frontend: `cd frontend && flutter pub get`
3. **Building the Project (if applicable):**
   - Flutter builds (examples): `flutter build apk --release --dart-define=ENV=prod`, `flutter build web --release --dart-define=ENV=prod`
4. **Running the Application/Service:**
   - Backend (Docker): `docker compose up --build` (exposes FastAPI on `http://localhost:20757`)
   - Backend (local): `cd backend && alembic upgrade head && uvicorn app.main:app --reload`
   - Frontend (Web dev): `cd frontend && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=ENV=dev`
5. **Running Tests:**
   - Backend: `cd backend && pytest`
   - Frontend: `cd frontend && flutter test` (project notes indicate minimal/no tests yet)
6. **Common Issues:** Ensure `.env` contains `DATABASE_URL` and `ENVIRONMENT` for backend; Docker port `20757` maps to app port `8000`; for frontend, set `.env.dev` with `API_BASE_URL=http://localhost:20757` and initialize via `AppConfig`.

## Helpful Resources

- **Documentation:** `docs/tech_stack.md`, `docs/mvp.md`, `docs/flutter_build_guide.md`, `docs/docker_upgrade_guide.md`
- **Issue Tracker:** `https://github.com/Netherman2440/squads` (use repository issues)
- **Contribution Guide:** Contribution guide not found
- **Communication Channels:** Communication channels not found
- **Learning Resources:** FastAPI, SQLAlchemy, Alembic, PostgreSQL, Docker, pytest, and Flutter docs are linked in `README.md`


