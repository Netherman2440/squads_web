# Squads

A Flutter web application for creating balanced teams in amateur sports matches, managing squads, players, matches, and simple tournaments. Built from scratch using Clean Architecture and feature-first organization.

## Table of Contents
- [Project Description](#project-description)
- [Tech Stack](#tech-stack)
- [Getting Started Locally](#getting-started-locally)
- [Project Status](#project-status)
- [License](#license)

## Project Description
Squads solves the chaos of team selection in amateur sports by providing deterministic, balanced team division proposals based on player rankings. Users can create squads, add players, generate drafts, record match results, and run simple tournaments. Rankings update automatically via event-sourcing deltas after each match.

This repository is a newer iteration of https://github.com/Netherman2440/squads. The original repo was my learning project (Flutter + Python); this one is full Flutter + Supabase.

Key features include:
- User accounts with roles (Owner, Admin, Member) and private squad invitations.
- Squad management (public/private visibility, up to 100 players per squad, 1 squad per owner).
- Player CRUD with per-squad rankings, stats, and trends.
- Drafting: Greedy algorithm with sorted proposals and balance scores.
- Matches: Create from drafts, score entry (home/away + metadata like penalties), and update rankings.
- Tournaments: Player selection, team drafting, match addition, and simple standings.
- Basic stats: Win/loss records, ranking trends, historical scores.
- Guest mode for viewing public squads.

MVP focuses on football; see [.ai/prd.md](.ai/prd.md) for full requirements, user stories, and success metrics (e.g., 50% logged-in users, 20% squad creation rate).

## Tech Stack
### Frontend
- **Framework**: Flutter (Dart) for web.
- **State Management**: Riverpod (flutter_riverpod).
- **Routing**: GoRouter.
- **Charts**: fl_chart.
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
- **CI/CD**: GitHub Actions.
- **Hosting**: Vercel (Flutter web build).

For full details, see [.ai/tech-stack.md](.ai/tech-stack.md).

## Getting Started Locally
### Prerequisites
- Flutter SDK (^3.9.2) installed (see [Flutter docs](https://docs.flutter.dev/get-started/install)).
- Supabase account and project (see [Supabase](https://supabase.com/)).
- Supabase keys (publishable/anon key for frontend).

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
   - Configure environment (create `.env` in `app/`):
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_publishable_key
     ```
     (Use the URL and publishable/anon client key from your Supabase project, not the service role/secret API key.)
   - Run in web mode:
     ```bash
     flutter run -d chrome --dart-define-from-file=.env
     ```
     (The app uses `--dart-define-from-file` instead of `flutter_dotenv`.)

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

