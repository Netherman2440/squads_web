# Squads – Plan bazy danych (PostgreSQL)

> **Wersja:** MVP
> **Zgodność:** PRD + decyzje z sesji planowania, zoptymalizowane pod FastAPI + SQLAlchemy + PostgreSQL
> **Uwaga dot. zmian:** Pozycje oznaczone **[Zmiana vs. aktualny plan]** odbiegają od `<current_db_plan>` i odzwierciedlają uzgodnienia z sesji.

---

## 1. Lista tabel z ich kolumnami, typami danych i ograniczeniami

### 1.0. Rozszerzenia i typy (globalne)

* **Rozszerzenia**

  * `citext` – case‑insensitive tekst dla unikalności nazw. **[Zmiana vs. aktualny plan]**
  * `pgcrypto` (lub alternatywnie `uuid-ossp`) – jeśli UUIDy mają być generowane po stronie DB (w MVP mogą być dostarczane przez aplikację).

* **ENUMy**

  * `squad_visibility` = `('public','private')` – domyślnie `'public'`. **[Zmiana vs. aktualny plan]**
  * `sport_type` = `('football')` – przygotowane pod rozszerzenia. **[Zmiana vs. aktualny plan]**
  * `side_enum` = `('home','away')`. **[Zmiana vs. aktualny plan]**
  * `match_score_type` = `('regular','penalties','walkover','cancelled')`. **[Zmiana vs. aktualny plan]**
  * `user_squad_role` = `('owner','admin','member','invited','pending')` – jedna kolumna łącząca role i status zaproszeń. **[Zmiana vs. aktualny plan]**


* **Typ złożony**

  * `score_pair` = `(home SMALLINT, away SMALLINT)` – wynik meczu jako krotka. **[Zmiana vs. aktualny plan]**

---

### 1.1. `users`

Identyfikacja użytkowników; autoryzacja obsługiwana przez Supabase Auth. Poniższa tabela przechowuje dodatkowe dane/profil w aplikacji oraz powiązanie z kontem z autentykacji. **[Zmiana vs. aktualny plan]**

| Kolumna         | Typ         | Ograniczenia                                                     |
| --------------- | ----------- | ---------------------------------------------------------------- |
| `user_id`       | UUID        | PK; **domyślnie** brane z Supabase Auth  |
| `email`         | CITEXT      | NOT NULL; UNIQUE **[Zmiana vs. aktualny plan]**                  |
| `created_at`    | TIMESTAMPTZ | NOT NULL DEFAULT now()                                           |
| `last_login_at` | TIMESTAMPTZ | NULLABLE                                                         |

---

### 1.2. `squads`

Składy z widocznością i właścicielem.

| Kolumna      | Typ                | Ograniczenia                                                                          |
| ------------ | ------------------ | ------------------------------------------------------------------------------------- |
| `squad_id`   | UUID               | PK                                                                                    |
| `owner_id`   | UUID               | NOT NULL; FK → `users(user_id)` **ON DELETE RESTRICT** **[Zmiana vs. aktualny plan]** |
| `name`       | TEXT               | NOT NULL                                                                              |
| `visibility` | `squad_visibility` | NOT NULL DEFAULT `'public'` **[Zmiana vs. aktualny plan]**                            |
| `sport_type` | `sport_type`       | NOT NULL DEFAULT `'football'` **[Zmiana vs. aktualny plan]**                          |
| `created_at` | TIMESTAMPTZ        | NOT NULL DEFAULT now()                                                                |

> **Limit 1 skład na Ownera** – egzekwowany **w API** w MVP (brak DB‑constraint zgodnie z decyzją). **[Zmiana vs. aktualny plan]**

---

### 1.3. `user_squads`

Członkostwa + zaproszenia (rola jako jeden ENUM).

| Kolumna      | Typ               | Ograniczenia                                        |
| ------------ | ----------------- | --------------------------------------------------- |
| `user_id`    | UUID              | NOT NULL; FK → `users(user_id)` ON DELETE CASCADE   |
| `squad_id`   | UUID              | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE |
| `role`       | `user_squad_role` | NOT NULL **[Zmiana vs. aktualny plan]**             |
| `created_at` | TIMESTAMPTZ       | NOT NULL DEFAULT now()                              |

**Klucze:**
PK `(user_id, squad_id)`

> **Usunięto** `player_id` z `user_squads` (brak mapowania user↔player w MVP). **[Zmiana vs. aktualny plan]**

---

### 1.4. `players`

Zawodnicy w obrębie składu z per‑squad rankingiem.

| Kolumna          | Typ          | Ograniczenia                                                        |
| ---------------- | ------------ | ------------------------------------------------------------------- |
| `player_id`      | UUID         | PK                                                                  |
| `squad_id`       | UUID         | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE                 |
| `name`           | CITEXT       | NOT NULL                                                            |
| `position`       | TEXT         | NULLABLE (MVP: dowolny tekst)                                       |
| `base_score`    | INTEGER | NOT NULL DEFAULT 0                 |
| `score` | FLOAT  | NOT NULL  |
| `created_at`     | TIMESTAMPTZ  | NOT NULL DEFAULT now()                                              |

**Klucze/ograniczenia:**
UNIQUE `(squad_id, name)` – case‑insensitive dzięki `CITEXT`. **[OPCJONALNA Zmiana vs. aktualny plan]**

---

### 1.6. `tournaments`

Turnieje i ich akceptowany zestaw draftu.

| Kolumna                 | Typ                 | Ograniczenia                                                                          |
| ----------------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `tournament_id`         | UUID                | PK                                                                                    |
| `squad_id`              | UUID                | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE                                   |
| `name`                  | TEXT                | NOT NULL                                                                              |
| `created_at`            | TIMESTAMPTZ         | NOT NULL DEFAULT now()                                                                |

---

### 1.7. `tournament_teams`

Tożsamości drużyn turniejowych (edytowalne nazwy/kolory).

| Kolumna              | Typ         | Ograniczenia                                                  |
| -------------------- | ----------- | ------------------------------------------------------------- |
| `tournament_team_id` | UUID        | PK **[Zmiana vs. aktualny plan – nowa tabela]**               |
| `tournament_id`      | UUID        | NOT NULL; FK → `tournaments(tournament_id)` ON DELETE CASCADE |
| `name`               | TEXT        | NULLABLE                                                      |
| `color`              | TEXT        | NULLABLE                                                      |
| `created_at`         | TIMESTAMPTZ | NOT NULL DEFAULT now()                                        |

**Unikalność (opcjonalnie):** UNIQUE `(tournament_id, name)` (jeśli nazwy muszą być unikalne w ramach turnieju)

---

### 1.8. `tournament_team_players`

Składy drużyn turniejowych.

| Kolumna              | Typ  | Ograniczenia                                                                                                                               |
| -------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `tournament_team_id` | UUID | NOT NULL; FK → `tournament_teams(tournament_team_id)` ON DELETE CASCADE                                                                    |
| `tournament_id`      | UUID | NOT NULL; **zduplikowane** dla spójności referencyjnej; FK → `tournaments(tournament_id)` ON DELETE CASCADE **[Zmiana vs. aktualny plan]** |
| `player_id`          | UUID | NOT NULL; FK → `players(player_id)` ON DELETE CASCADE                                                                                      |

**Klucze/unikalności:**

* PK `(tournament_team_id, player_id)`
* UNIQUE `(tournament_id, player_id)` – gracz może być tylko w jednej drużynie w danym turnieju. **[Zmiana vs. aktualny plan]**
* FK złożony: `(tournament_id, tournament_team_id)` → `tournament_teams(tournament_id, tournament_team_id)` (wymaga UNIQUE na `tournament_teams(tournament_id, tournament_team_id)` – patrz niżej w indeksach). **[Zmiana vs. aktualny plan]**

---

### 1.9. `matches`

Mecze, wynik i workflow zatwierdzania.

| Kolumna               | Typ                     | Ograniczenia                                                               |
| --------------------- | ----------------------- | -------------------------------------------------------------------------- |
| `match_id`            | UUID                    | PK                                                                         |
| `squad_id`            | UUID                    | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE                        |
| `tournament_id`       | UUID                    | NULLABLE; FK → `tournaments(tournament_id)` ON DELETE CASCADE              |
| `score_type`         | `match_score_type`     | NULLABLE (ustawiane po wprowadzeniu wyniku) **[Zmiana vs. aktualny plan]** |
| `home_score`               | SMALLINT            | NULLABLE **[Zmiana vs. aktualny plan]**  |
| `away_score`               | SMALLINT            | NULLABLE **[Zmiana vs. aktualny plan]**  |
| `score_meta`          | JSONB                   | NOT NULL DEFAULT '{}'::jsonb **[Zmiana vs. aktualny plan]**                |
| `created_at`          | TIMESTAMPTZ             | NOT NULL DEFAULT now()                                                     |

---

### 1.10. `teams`

Drużyny per mecz (snapshot; bez wyniku; z atrybutem strony).

| Kolumna              | Typ         | Ograniczenia                                                                                                   |
| -------------------- | ----------- | -------------------------------------------------------------------------------------------------------------- |
| `team_id`            | UUID        | PK                                                                                                             |
| `match_id`           | UUID        | NOT NULL; FK → `matches(match_id)` ON DELETE CASCADE                                                           |
| `side`               | `side_enum` | NOT NULL **[Zmiana vs. aktualny plan]**                                                                        |
| `name`               | TEXT        | NULLABLE                                                                                                       |
| `color`              | TEXT        | NULLABLE                                                                                                       |
| `created_at`         | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                                                         |

**Unikalności:**

* UNIQUE `(match_id, side)` – dokładnie jedna drużyna na stronę. **[Zmiana vs. aktualny plan]**
* UNIQUE `(match_id, team_id)` – na potrzeby złożonego FK z `team_players`. **[Zmiana vs. aktualny plan]**

> **Usunięto** z `teams`: `squad_id`, `score`. **[Zmiana vs. aktualny plan]**

---

### 1.11. `team_players`

Przypisanie graczy do drużyn w kontekście meczu (snapshoty).

| Kolumna      | Typ         | Ograniczenia                                                                                  |
| ------------ | ----------- | --------------------------------------------------------------------------------------------- |
| `match_id`   | UUID        | NOT NULL; FK → `matches(match_id)` ON DELETE CASCADE                                          |
| `team_id`    | UUID        | NOT NULL                                                                                      |
| `player_id`  | UUID        | NOT NULL; FK → `players(player_id)` ON DELETE RESTRICT (gracz nie powinien znikać z historii) |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                                        |

**Klucze/Unikalności:**

* PK `(match_id, team_id, player_id)` **[Zmiana vs. aktualny plan]**
* **Złożony FK:** `(match_id, team_id)` → `teams(match_id, team_id)` **[Zmiana vs. aktualny plan]**
* UNIQUE `(match_id, player_id)` – gracz nie może być w obu drużynach jednego meczu. **[Zmiana vs. aktualny plan]**

> **Usunięto** `squad_id` z `team_players`. **[Zmiana vs. aktualny plan]**

---

### 1.12. `score_history`

Event‑sourcing rankingów (delty), z możliwością manualnych korekt.

| Kolumna            | Typ          | Ograniczenia                                          |
| ------------------ | ------------ | ----------------------------------------------------- |
| `score_history_id` | UUID         | PK                                                    |
| `player_id`        | UUID         | NOT NULL; FK → `players(player_id)` ON DELETE CASCADE |
| `match_id`         | UUID         | NULLABLE; FK → `matches(match_id)` ON DELETE CASCADE  |
| `delta`            | NUMERIC(6,3) | NOT NULL                                              |
| `previous_rating`  | NUMERIC(6,3) | NOT NULL **[Zmiana vs. aktualny plan]**               |
| `new_rating`       | NUMERIC(6,3) | NOT NULL **[Zmiana vs. aktualny plan]**               |
| `created_at`       | TIMESTAMPTZ  | NOT NULL DEFAULT now()                                |

**Unikalność warunkowa:**

* UNIQUE `(player_id, match_id)` **WHERE `match_id` IS NOT NULL**. **[Zmiana vs. aktualny plan]**

> **Brak** kolumn audytowych `changed_by/reason` w MVP – zgodnie z decyzją (audyt operacji w osobnej tabeli). **[Zmiana vs. aktualny plan]**


---

## 2. Relacje między tabelami (kardynalność)

* `users` **1—N** `squads` (przez `squads.owner_id`)
* `users` **N—N** `squads` (przez `user_squads`)
* `squads` **1—N** `players`
* `squads` **1—N** `matches`
* `squads` **1—N** `tournaments`
* `players` **N—N** `matches` (przez `team_players`; dodatkowo UNIQUE `(match_id, player_id)`)
* `matches` **1—N** `teams`
* `teams` **N—N** `players` (przez `team_players`)
* `tournaments` **1—N** `tournament_teams`
* `tournament_teams` **N—N** `players` (przez `tournament_team_players`; dodatkowo UNIQUE `(tournament_id, player_id)`)
* `matches` **N—1** `tournaments` (NULLABLE)
* `teams` **N—1** `tournament_teams` (NULLABLE; snapshot referencji)
* `players` **1—N** `score_history`
* `matches` **1—N** `score_history` (NULLABLE FK; manualne korekty mają `match_id IS NULL`)

---

## 3. Indeksy

> W MVP ograniczamy dodatkowe indeksy, pozostawiając te wynikające z PK/FK/UNIQUE. Poniższe **zalecane** indeksy są lekkie i zgodne z uzgodnieniami.

* **Unikalności / klucze (implikują indeksy)**

  * `users(email)` UNIQUE
  * `players(squad_id, name)` UNIQUE (CITEXT)
  * `teams(match_id, side)` UNIQUE
  * `teams(match_id, team_id)` UNIQUE (na potrzeby złożonego FK)
  * `team_players(match_id, player_id)` UNIQUE
  * `tournament_team_players(tournament_id, player_id)` UNIQUE
  * **(wspierające FK złożone)**: UNIQUE `tournament_teams(tournament_id, tournament_team_id)`

* **Wydajnościowe (opcjonalne, niskim kosztem)**

  * `matches`:

    * INDEX `matches_squad_played_at_idx` ON `(squad_id, played_at DESC)`
    * INDEX `matches_tournament_idx` ON `(tournament_id)`
  * `score_history`:

    * INDEX `score_history_player_time_idx` ON `(player_id, created_at DESC)`
    * INDEX `score_history_match_idx` ON `(match_id)` WHERE `match_id IS NOT NULL`
  * `players`:

    * INDEX `players_squad_idx` ON `(squad_id)`
  * `user_squads`:

    * INDEX `user_squads_user_idx` ON `(user_id)`
    * INDEX `user_squads_squad_idx` ON `(squad_id)`


> **Nie włączamy** w MVP indeksu `UNIQUE(squads.owner_id)` (limit 1 skład na Ownera – polityka aplikacyjna).

---

## 4. Zasady PostgreSQL (RLS)

* **MVP:** **brak RLS** – zgodnie z decyzją (kontrola dostępu i widoczności egzekwowana wyłącznie w API na podstawie `user_squads.role` i `squads.visibility`).
* **Szkic po‑MVP (opcjonalnie):**

  * Aktywować RLS dla: `squads`, `players`, `matches`, `tournaments`, `teams`, `team_players`.
  * Polityki przykładowe:

    * Publiczny odczyt `squads` z `visibility='public'`.
    * Dla `visibility='private'` odczyt/ zapis wyłącznie gdy istnieje wiersz w `user_squads` z `(user_id=current_setting('app.user_id')::uuid)` i `role IN ('owner','admin','member')`.
    * Osobne polityki dla operacji administracyjnych (np. zatwierdzanie wyników) dla `role IN ('owner')`.
  * Wymaga ustawiania `app.user_id` na połączeniu (np. `SET LOCAL` w warstwie API).

---

## 5. Dodatkowe uwagi i decyzje projektowe

* **Wynik meczu jako krotka** `score_pair` (home, away) w `matches.score`; `result_type` + `score_meta(JSONB)` dla metadanych (np. `{ "penalties": {"home":5,"away":4}, "walkover": true }`). **[Zmiana vs. aktualny plan]**
* **Teams/TeamPlayers – snapshoty**: `teams` przechowuje tylko `side`, `name`, `color` **brak** `score`, **brak** `squad_id`. Integralność składu zapewnia złożony FK w `team_players` oraz `UNIQUE(match_id, player_id)`. **[Zmiana vs. aktualny plan]**
* **Turnieje**: wprowadzono `tournament_teams` i `tournament_team_players`; mecze turniejowe generują nowe `teams` (snapshoty). Dodano `tournaments.teams_expected_count`. **[Zmiana vs. aktualny plan]**

* **Score history**: `match_id` może być `NULL` dla manualnych korekt; partial UNIQUE `(player_id, match_id)` utrzymuje jeden wpis per gracz‑mecz. **[Zmiana vs. aktualny plan]**
* **Widoczność składów**: `squads.visibility` z DEFAULT `'public'` (filtrowanie po stronie API – brak RLS w MVP). **[Zmiana vs. aktualny plan]**
* **Unikalność nazw graczy**: w obrębie składu, case‑insensitive dzięki `CITEXT`. **[Zmiana vs. aktualny plan]**

* **Zgodność z SQLAlchemy**: typ złożony `score_pair` może wymagać `TypeDecorator`/composite mapping; alternatywnie (fallback) dwa pola `score_home`/`score_away` + widok/materialized view jako interfejs zgodny z krotką (do rozważenia, jeśli integracja okaże się kłopotliwa).
* **Kasowanie danych**: twarde kasowanie; `ON DELETE CASCADE` tam, gdzie uzgodniono (dzieci obiektów domenowych). Brak soft‑delete w MVP.
* **Limity**: limit 1 skład na Ownera i do 100 graczy na skład – egzekwowane w API (brak triggerów/constraintów liczności w DB, zgodnie z decyzją).
* **SportType**: `squad.sport_type`  przewiduje przyszłe sporty (MVP: tylko `football`).


---

