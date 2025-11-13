Frontend:
Flutter (Dart)
State:
Riverpod (flutter_riverpod)
Routing:
MaterialApp (GoRouter – planned)

Notes (frontend):
- The previous Flutter frontend from the legacy monorepo is treated as
  **legacy UI** and used only as UX inspiration (flows, layout, copy).
- The new Squads Web frontend is being built **from scratch** in
  Flutter with Clean Architecture (DDD) and feature-first structure;
  no legacy Flutter code is reused as a base.

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