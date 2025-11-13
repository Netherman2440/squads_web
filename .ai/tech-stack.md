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
Python
FastAPI + Pydantic
Dataclasses bridging ORM to business logic
Auth: JWT (python-jose), password hashing (passlib+bcrypt)
Server: Uvicorn
HTTP client: httpx (tests)

Database:
PostgreSQL (prod) + ORM: SQLAlchemy
SQLite (tests)

Migrations:
Alembic

Testing:
pytest (backend)

Env/config:
python-dotenv (backend), flutter_dotenv (frontend)

Charts (frontend):
fl_chart

Local runtime:
docker compose

CI/CD i Hosting:
- GitHub Actions (planned)
- DigitalOcean via Docker image (planned)