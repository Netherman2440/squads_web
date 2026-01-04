# Squads – Plan bazy danych (PostgreSQL)

> **Wersja:** MVP
> **Zgodność:** PRD + decyzje z sesji planowania, zgodne z aktualnymi migracjami Supabase (PostgreSQL)
> **Uwaga dot. zmian:** Pozycje oznaczone **[Zmiana vs. aktualny plan]** odbiegają od `<current_db_plan>` i odzwierciedlają uzgodnienia z sesji.

---

## 1. Lista tabel z ich kolumnami, typami danych i ograniczeniami

### 1.0. Rozszerzenia i typy (globalne)

* **Rozszerzenia**

  * `pgcrypto` – UUID generowane po stronie DB (zgodnie z migracjami).

* **ENUMy**

  * `squad_visibility` = `('public','private')` – domyślnie `'public'`.
  * `sport_type` = `('football')` – przygotowane pod rozszerzenia.
  * `side_enum` = `('home','away')`.
  * `match_score_type` = `('regular','penalties','walkover','cancelled')`.
  * `user_squad_role` = `('none','owner','admin','member','pending','invited','declined','removed')` – jedna kolumna łącząca role i status zaproszeń.


* **Typ złożony**

  * `score_pair` = `(home SMALLINT, away SMALLINT)` – typ zdefiniowany, obecnie nieużywany w tabeli `matches`.

---

### 1.1. `users`

Identyfikacja użytkowników; autoryzacja obsługiwana przez Supabase Auth.
Tabela `public.users` jest kopią profilu użytkownika do joinów (tworzona w migracjach).

| Kolumna      | Typ         | Ograniczenia                                   |
| ------------ | ----------- | ---------------------------------------------- |
| `user_id`    | UUID        | PK; FK → `auth.users(id)` ON DELETE CASCADE    |
| `email`      | TEXT        | NOT NULL; UNIQUE                               |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now()                         |

---

### 1.2. `squads`

Składy z widocznością i właścicielem.

| Kolumna                 | Typ                | Ograniczenia                                                              |
| ----------------------- | ------------------ | ------------------------------------------------------------------------- |
| `squad_id`              | UUID               | PK                                                                        |
| `owner_id`              | UUID               | NOT NULL; FK → `auth.users(id)` ON DELETE RESTRICT                        |
| `name`                  | TEXT               | NOT NULL                                                                  |
| `visibility`            | `squad_visibility` | NOT NULL DEFAULT `'public'`                                               |
| `sport_type`            | `sport_type`       | NOT NULL DEFAULT `'football'`                                             |
| `ranking_update`        | BOOLEAN            | NOT NULL DEFAULT true                                                     |
| `ranking_multiplier`    | INTEGER            | NOT NULL DEFAULT 5; CHECK `ranking_multiplier BETWEEN 1 AND 10`           |
| `use_experience_factor` | BOOLEAN            | NOT NULL DEFAULT true                                                     |
| `created_at`            | TIMESTAMPTZ        | NOT NULL DEFAULT now()                                                    |

> **Limit 1 skład na Ownera** – egzekwowany **w API** w MVP (brak DB‑constraint zgodnie z decyzją). **[Zmiana vs. aktualny plan]**

---

### 1.3. `user_squads`

Członkostwa + zaproszenia (rola jako jeden ENUM).

| Kolumna      | Typ               | Ograniczenia                                        |
| ------------ | ----------------- | --------------------------------------------------- |
| `user_id`    | UUID              | NOT NULL; FK → `auth.users(id)` ON DELETE CASCADE   |
| `squad_id`   | UUID              | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE |
| `role`       | `user_squad_role` | NOT NULL                                            |
| `created_at` | TIMESTAMPTZ       | NOT NULL DEFAULT now()                              |

**Klucze:**
PK `(user_id, squad_id)`

> **Usunięto** `player_id` z `user_squads` (brak mapowania user↔player w MVP). **[Zmiana vs. aktualny plan]**

---

### 1.4. `players`

Zawodnicy w obrębie składu z per‑squad rankingiem.

| Kolumna      | Typ          | Ograniczenia                                                       |
| ------------ | ------------ | ------------------------------------------------------------------ |
| `player_id`  | UUID         | PK                                                                 |
| `squad_id`   | UUID         | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE                |
| `name`       | TEXT         | NOT NULL                                                           |
| `position`   | TEXT         | NULLABLE (MVP: dowolny tekst)                                      |
| `base_score` | INTEGER      | NOT NULL DEFAULT 0; CHECK `base_score BETWEEN 0 AND 100`           |
| `score`      | NUMERIC(5,2) | NOT NULL; CHECK `score BETWEEN 0 AND 100`                          |
| `created_at` | TIMESTAMPTZ  | NOT NULL DEFAULT now()                                             |

**Klucze/ograniczenia:**
UNIQUE `(squad_id, name)`

---

### 1.6. `tournaments`

Turnieje i ich akceptowany zestaw draftu.

| Kolumna                | Typ         | Ograniczenia                                        |
| ---------------------- | ----------- | --------------------------------------------------- |
| `tournament_id`        | UUID        | PK                                                  |
| `squad_id`             | UUID        | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE |
| `name`                 | TEXT        | NULLABLE                                            |
| `teams_expected_count` | INTEGER     | NULLABLE                                            |
| `created_at`           | TIMESTAMPTZ | NOT NULL DEFAULT now()                              |

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

Mecze i wynik (bez workflow zatwierdzania).

| Kolumna               | Typ                     | Ograniczenia                                                               |
| --------------------- | ----------------------- | -------------------------------------------------------------------------- |
| `match_id`            | UUID                    | PK                                                                         |
| `squad_id`            | UUID                    | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE                        |
| `tournament_id`       | UUID                    | NULLABLE; FK → `tournaments(tournament_id)` ON DELETE CASCADE              |
| `score_type`         | `match_score_type`     | NULLABLE (ustawiane po wprowadzeniu wyniku) **[Zmiana vs. aktualny plan]** |
| `home_score`               | SMALLINT            | NULLABLE **[Zmiana vs. aktualny plan]**  |
| `away_score`               | SMALLINT            | NULLABLE **[Zmiana vs. aktualny plan]**  |
| `score_meta`          | JSONB                   | NOT NULL DEFAULT '{}'::jsonb **[Zmiana vs. aktualny plan]**                |
| `played_at`           | TIMESTAMPTZ             | NULLABLE                                                                  |
| `created_at`          | TIMESTAMPTZ             | NOT NULL DEFAULT now()                                                     |

---

### 1.10. `teams`

Drużyny per mecz (snapshot; bez wyniku; z atrybutem strony).

| Kolumna         | Typ         | Ograniczenia                                                                                     |
| --------------- | ----------- | ------------------------------------------------------------------------------------------------ |
| `team_id`       | UUID        | PK                                                                                               |
| `match_id`      | UUID        | NOT NULL; FK → `matches(match_id)` ON DELETE CASCADE                                             |
| `tournament_id` | UUID        | NULLABLE; FK → `tournaments(tournament_id)` ON DELETE SET NULL                                   |
| `side`          | `side_enum` | NOT NULL                                                                                         |
| `name`          | TEXT        | NULLABLE                                                                                         |
| `color`         | TEXT        | NULLABLE                                                                                         |
| `created_at`    | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                                           |

**Unikalności:**

* UNIQUE `(match_id, side)` – dokładnie jedna drużyna na stronę. **[Zmiana vs. aktualny plan]**
* UNIQUE `(match_id, team_id)` – na potrzeby złożonego FK z `team_players`. **[Zmiana vs. aktualny plan]**

> **Usunięto** z `teams`: `squad_id`, `score`. **[Zmiana vs. aktualny plan]**

---

### 1.11. `team_players`

Przypisanie graczy do drużyn w kontekście meczu (snapshoty).

| Kolumna         | Typ         | Ograniczenia                                                                                  |
| --------------- | ----------- | --------------------------------------------------------------------------------------------- |
| `match_id`      | UUID        | NOT NULL; FK → `matches(match_id)` ON DELETE CASCADE                                          |
| `team_id`       | UUID        | NOT NULL; FK → `teams(team_id)` ON DELETE CASCADE                                             |
| `player_id`     | UUID        | NOT NULL; FK → `players(player_id)` ON DELETE RESTRICT (gracz nie powinien znikać z historii) |
| `tournament_id` | UUID        | NULLABLE; FK → `tournaments(tournament_id)` ON DELETE SET NULL                                |
| `created_at`    | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                                        |

**Klucze/Unikalności:**

* PK `(match_id, team_id, player_id)` **[Zmiana vs. aktualny plan]**
* **Złożony FK:** `(match_id, team_id)` → `teams(match_id, team_id)` **[Zmiana vs. aktualny plan]**
* UNIQUE `(match_id, player_id)` – gracz nie może być w obu drużynach jednego meczu. **[Zmiana vs. aktualny plan]**

> **Usunięto** `squad_id` z `team_players`. **[Zmiana vs. aktualny plan]**

---

### 1.12. `ranking_history`

Historia rankingów (snapshot + delta), z możliwością manualnych korekt.

| Kolumna              | Typ          | Ograniczenia                                          |
| -------------------- | ------------ | ----------------------------------------------------- |
| `ranking_history_id` | UUID         | PK                                                    |
| `player_id`          | UUID         | NOT NULL; FK → `players(player_id)` ON DELETE CASCADE |
| `match_id`           | UUID         | NULLABLE; FK → `matches(match_id)` ON DELETE SET NULL |
| `ranking`            | NUMERIC(6,3) | NOT NULL                                              |
| `change`             | NUMERIC(6,3) | NULLABLE                                              |
| `match_score`        | JSONB        | NULLABLE                                              |
| `created_at`         | TIMESTAMPTZ  | NOT NULL DEFAULT now()                                |
| `updated_at`         | TIMESTAMPTZ  | NULLABLE                                              |

**Unikalność warunkowa:**

* UNIQUE `(player_id, match_id)` **WHERE `match_id` IS NOT NULL**

> **Brak** kolumn audytowych `changed_by/reason` w MVP – zgodnie z decyzją (audyt operacji w osobnej tabeli).


---

## 2. Relacje między tabelami (kardynalność)

* `auth.users` **1—N** `squads` (przez `squads.owner_id`)
* `auth.users` **N—N** `squads` (przez `user_squads`)
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
* `players` **1—N** `ranking_history`
* `matches` **1—N** `ranking_history` (NULLABLE FK; manualne korekty mają `match_id IS NULL`)

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
  * `ranking_history`:

    * INDEX `ranking_history_player_idx` ON `(player_id)`
    * INDEX `ranking_history_match_idx` ON `(match_id)` WHERE `match_id IS NOT NULL`
  * `players`:

    * INDEX `players_squad_idx` ON `(squad_id)`
  * `user_squads`:

    * INDEX `user_squads_user_idx` ON `(user_id)`
    * INDEX `user_squads_squad_idx` ON `(squad_id)`


> **Nie włączamy** w MVP indeksu `UNIQUE(squads.owner_id)` (limit 1 skład na Ownera – polityka aplikacyjna).

---

## 4. Zasady PostgreSQL (RLS)

* **MVP:** **RLS włączone** – zgodnie z aktualnymi migracjami Supabase.
  * Polityki są oparte o `auth.uid()` oraz role z `user_squads` (`owner/admin/member` dla dostępu).
  * Dla ról wrażliwych (insert/update/delete) wymagane są role `owner/admin`.

---

## 5. Dodatkowe uwagi i decyzje projektowe

* **Wynik meczu**: `home_score` + `away_score` w `matches`, `score_type` + `score_meta(JSONB)` dla metadanych (np. `{ "penalties": {"home":5,"away":4}, "walkover": true }`).
* **Teams/TeamPlayers – snapshoty**: `teams` przechowuje tylko `side`, `name`, `color` **brak** `score`, **brak** `squad_id`. Integralność składu zapewnia złożony FK w `team_players` oraz `UNIQUE(match_id, player_id)`. **[Zmiana vs. aktualny plan]**
* **Turnieje**: wprowadzono `tournament_teams` i `tournament_team_players`; mecze turniejowe generują nowe `teams` (snapshoty). Dodano `tournaments.teams_expected_count`. **[Zmiana vs. aktualny plan]**

* **Ranking history**: `match_id` może być `NULL` dla manualnych korekt; partial UNIQUE `(player_id, match_id)` utrzymuje jeden wpis per gracz‑mecz.
* **Widoczność składów**: `squads.visibility` z DEFAULT `'public'` (filtrowanie po stronie API – brak RLS w MVP). **[Zmiana vs. aktualny plan]**
* **Unikalność nazw graczy**: w obrębie składu, case‑insensitive dzięki `CITEXT`. **[Zmiana vs. aktualny plan]**

* **Score pair**: typ złożony `score_pair` jest zdefiniowany, ale obecnie nieużywany; w razie potrzeby można go wykorzystać w przyszłości.
* **Kasowanie danych**: twarde kasowanie; `ON DELETE CASCADE` tam, gdzie uzgodniono (dzieci obiektów domenowych). Brak soft‑delete w MVP.
* **Limity**: limit 1 skład na Ownera i do 100 graczy na skład – egzekwowane w API (brak triggerów/constraintów liczności w DB, zgodnie z decyzją).
* **SportType**: `squad.sport_type`  przewiduje przyszłe sporty (MVP: tylko `football`).


---
