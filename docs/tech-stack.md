Frontend:
Flutter (Dart)
State:
Riverpod (flutter_riverpod)
- AsyncValue & AsyncNotifier for state management
Routing:
MaterialApp (GoRouter – planned)

Notes (frontend):
- The previous Flutter frontend from the legacy monorepo is treated as
  **legacy UI** and used only as UX inspiration (flows, layout, copy).
- The new Squads Web frontend is being built **from scratch** in
  Flutter with Clean Architecture (DDD) and feature-first structure;
  no legacy Flutter code is reused as a base.

Architecture & Patterns:
- **Clean Architecture**: Feature-first folders (domain, infrastructure, application, presentation).
- **Error Handling**: 
  - Domain `Failure` hierarchy (AuthFailure, NetworkFailure, etc.).
  - `AsyncValue.guard` in Notifiers for automatic error catching.
  - `ref.listen` in UI for side-effects (SnackBars).
  - Explicit repository try-catch blocks mapping external exceptions to Domain Failures via extensions.
- **Async State**: 
  - `AsyncValue` for all data-fetching states (loading/data/error).
  - Global Loading indicators for blocking operations.

Backend:
Supabase (BaaS)
- Supabase Auth (email/password, OAuth) for user authentication
- Supabase REST (PostgREST) and RPC for data access
- Row Level Security (RLS) policies for authorization
- SQL functions and triggers for domain logic
- Optional Supabase Edge Functions (Deno/TypeScript) for custom workflows

Database:
Supabase PostgreSQL (managed)

Migrations:
Supabase migrations (`supabase db` via Supabase CLI)

Testing:
- Frontend: `flutter_test`
- Backend: SQL-level tests and validation via Supabase migrations (TBD)

Env/config:
Supabase project settings and environment variables, `flutter_dotenv` (frontend)

Charts (frontend):
fl_chart

Local runtime:
- Supabase Cloud for managed environment
- Optional: Supabase CLI (Docker-based) for local Supabase instance

CI/CD i Hosting:
- GitHub Actions (planned)
- Hosting for Flutter Web build (e.g. static hosting or Supabase Storage + CDN, planned)
