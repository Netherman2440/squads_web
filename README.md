# Squads

A Flutter web application for creating balanced teams in amateur sports matches, managing squads, players, matches, and simple tournaments. Built from scratch using Clean Architecture and feature-first organization.

## Table of Contents
- [Project Description](#project-description)
- [Tech Stack](#tech-stack)
- [Getting Started Locally](#getting-started-locally)
- [Available Scripts](#available-scripts)
- [Project Scope](#project-scope)
- [Project Status](#project-status)
- [License](#license)

## Project Description
Squads solves the chaos of team selection in amateur sports by providing deterministic, balanced team division proposals based on player rankings. Users can create squads, add players, generate drafts, record match results, and run simple tournaments. Rankings update automatically via event-sourcing deltas after each match.

Key features include:
- User accounts with roles (Owner, Admin, Member) and private squad invitations.
- Squad management (public/private visibility, up to 100 players per squad, 1 squad per owner).
- Player CRUD with per-squad rankings, stats, and trends.
- Drafting: Up to 20 sorted proposals for up to 16 players, with balance scores.
- Matches: Create from drafts, score entry (home/away + metadata like penalties), and update rankings.
- Tournaments: Player selection, team drafting, match addition, and simple standings.
- Basic stats: Win/loss records, ranking trends, historical scores.
- Guest mode for viewing public squads.

MVP focuses on football; see [.ai/prd.md](.ai/prd.md) for full requirements, user stories, and success metrics (e.g., 50% logged-in users, 20% squad creation rate).

## Tech Stack
### Frontend
- **Framework**: Flutter (Dart) for web.
- **State Management**: Riverpod (flutter_riverpod).
- **Routing**: GoRouter (planned), MaterialApp.
- **Charts**: fl_chart.
- **Other**: flutter_dotenv for environment config.
- **Architecture**: Clean Architecture (DDD) with feature-first structure. Legacy Flutter UI serves as UX inspiration only—no code reuse.

### Backend
- **Platform**: Supabase (Backend as a Service).
- **Auth**: Supabase Auth (email/password, OAuth).
- **API**: Supabase REST (PostgREST) and RPC endpoints.
- **Authorization**: Row Level Security (RLS) policies.
- **Domain Logic**: SQL functions, triggers, and optional Supabase Edge Functions (Deno/TypeScript).

### Database
- **Production**: Supabase PostgreSQL (managed).
- **Migrations**: Supabase migrations via Supabase CLI (`supabase db`).

### Testing
- **Frontend**: `flutter_test`.
- **Backend**: SQL-level checks and validation via Supabase migrations (TBD).

### Runtime & Deployment
- **Backend**: Supabase Cloud.
- **CI/CD**: GitHub Actions (planned).
- **Hosting**: Static hosting for Flutter Web (e.g. CDNs or Supabase Storage, planned).

For full details, see [.ai/tech-stack.md](.ai/tech-stack.md).

## Getting Started Locally
### Prerequisites
- Flutter SDK (^3.9.2) installed (see [Flutter docs](https://docs.flutter.dev/get-started/install)).
- Supabase account and project (see [Supabase](https://supabase.com/)).
- Supabase API keys (anon/public key for frontend, service role key kept server-side only if needed).

### Setup
1. **Clone the Repository**:
   ```bash
   git clone <your-repo-url>
   cd squads_web
   ```

2. **Frontend (Flutter Web)**:
   - Navigate to `app/`.
   - Install dependencies:
     ```bash
     flutter pub get
     ```
   - Configure environment (create `.env` in `app/` using `flutter_dotenv`):
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_key
     ```
     (Use the URL and anon key from your Supabase project.)
   - Run in web mode:
     ```bash
     flutter run -d chrome
     ```

3. **Supabase Project Configuration**:
   - Create a new project in the Supabase dashboard.
   - Apply your database schema and migrations (via SQL editor or `supabase db`).
   - Configure RLS policies and auth settings according to the PRD (roles, visibility, etc.).
   - Ensure the Flutter app's `SUPABASE_URL` and `SUPABASE_ANON_KEY` match the project.

4. **Optional: Supabase Local Development**:
   - Install the Supabase CLI and start a local instance:
     ```bash
     supabase start
     ```
   - Push your schema:
     ```bash
     supabase db push
     ```
   - Point the Flutter app to the local Supabase URL for local-only testing.

## Available Scripts
### Frontend (Flutter)
- Install dependencies: `flutter pub get`
- Run dev server (web): `flutter run -d chrome`
- Build for web: `flutter build web`
- Generate code (e.g., Riverpod/JSON): `flutter pub run build_runner build --delete-conflicting-outputs`
- Test: `flutter test`
- Lint: `flutter analyze`

### Supabase (optional, via Supabase CLI)
- Start local Supabase stack: `supabase start`
- Stop local Supabase stack: `supabase stop`
- Push database schema: `supabase db push`
- Reset local database: `supabase db reset`

For full CI/CD, see planned GitHub Actions workflows.

## Project Scope
### MVP Features (MUST)
- Authentication: Email/password login, guest mode, roles, invitations, RBAC.
- Squads: CRUD, visibility (public/private), member management (up to 100 players, 1 per owner).
- Players: CRUD, rankings, basic stats/trends (no user-player mapping).
- Drafting: Deterministic proposals (up to 20, sorted by balance) for ≤16 players.
- Matches: Create from drafts, score entry (home/away + meta), delta-based ranking updates.
- Tournaments: Player/team selection, draft acceptance, match addition, team edits, simple standings (W/L, goal diff).
- Stats: Matches played, win/loss, ranking history.
- Security: Audit logs, anti-spam limits (e.g., squad creation).

### SHOULD/NICE TO HAVE
- Sport type extension (football in MVP).
- Operational analytics exports.
- Player name suggestions/import (CSV).

### Out of Scope (Post-MVP)
- Subscriptions/access limits.
- Advanced draft rules, offline mode.
- User-player claiming, full anti-duplication.
- Advanced tournament tie-breakers, SEO.

### Limits & Assumptions
- 16-player draft hard limit; per-squad rankings.
- Online-only sessions; football-only MVP.
- Results affect only participating players.

See [.ai/prd.md](.ai/prd.md) for 19 user stories and metrics.

## Project Status
- **Development Stage**: MVP planning and initial implementation.
- **Completed**: Basic Flutter setup, GoRouter integration.
- **In Progress**: Core features (auth, squads, drafting) per Clean Architecture with Supabase backend.
- **Planned**: Full web build, Supabase integration (RLS, functions), CI/CD with GitHub Actions, and hosting for the Flutter Web build.
- **Version**: 1.0.0+1 (Flutter app).
- Open issues: Detailed in GitHub repo; contributions welcome (see CONTRIBUTING.md if added).

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. (TBD: Confirm exact license; defaults to MIT for open-source Flutter projects.)
