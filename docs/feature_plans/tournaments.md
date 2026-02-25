## Tournaments - plan implementacji (po doprecyzowaniu)

Zrodla: `docs/prd.md`, `docs/ui_plan.md`, uzgodnienia produktowe.

## 1. Uzgodnione decyzje

- Flow tworzenia: najpierw tworzymy rekord turnieju, potem draft i akceptacja propozycji.
- Tworzymy osobne tabele: `tournament_drafts` i `tournament_draft_payloads`.
- W `matches/teams` nie dodajemy `tournament_team_id`; mecze turniejowe to kopie aktualnych skladow turniejowych do standardowych `matches`, `teams`, `team_players`.
- Dodajemy status turnieju.
- Usuwamy kolumne `teams_expected_count` z `tournaments`.
- W turnieju nie dopuszczamy zawodnikow nieprzypisanych do druzyny (kazdy wybrany gracz musi byc dokladnie w 1 druzynie).
- RBAC jak w matches: read dla member/public wg visibility, write tylko owner/admin.
- Dla meczow turniejowych ukrywamy `redraft` i `rematch` w UI (`match.tournament_id != null`).
- Zakres wdrozenia: pelny flow.

## 2. User stories i flow

### 2.1 Lista turniejow skladu

- Wejscie z kafla `Tournaments` na stronie squadu.
- Routing: `/squads/:squadId/tournaments`.
- Lista pokazuje: nazwe, status, date utworzenia.
- Read-only wg visibility squadu; akcje tworzenia/edycji tylko owner/admin.

### 2.2 Tworzenie turnieju z draftu

- Start z listy turniejow lub CTA `Create Tournament`.
- Krok 1: tworzymy rekord turnieju (`status = drafting`).
- Krok 2: wybor graczy + liczby druzyn (`2..4`).
- Krok 3: relacje draftu (analogicznie jak w match flow):
  - `Razem` (gracze musza trafic do tego samego teamu),
  - `Przeciwko sobie` (gracze musza trafic do roznych teamow),
  - walidacje relacji sa zalezne od `teamCount`.
- Krok 4: generujemy i zapisujemy propozycje w `tournament_drafts` + `tournament_draft_payloads`.
- Krok 5: akceptacja propozycji tworzy `tournament_teams` oraz `tournament_team_players`, aktualizuje `status = active`.
- Po akceptacji przejscie do `/squads/:squadId/tournaments/:tournamentId`.

### 2.3 Widok turnieju

- Routing: `/squads/:squadId/tournaments/:tournamentId`.
- Widok zawiera:
  - skrot druzyn (nazwa, kolor, liczba graczy),
  - historie meczow turniejowych,
  - tabele wynikow (W/L + roznica bramek).
- Dla owner/admin: akcje edycji druzyn, dodawania meczu i zamkniecia turnieju.
- Dla owner/admin: mozliwosc podgladu innych propozycji draftu zapisanych dla turnieju.

### 2.4 Widok druzyn turniejowych

- Routing: `/squads/:squadId/tournaments/:tournamentId/teams`.
- Uklad analogiczny do podgladu draftu:
  - szerokie ekrany: druzyny obok siebie,
  - waskie ekrany: druzyny pod soba.

### 2.5 Edycja druzyn turniejowych

- Owner/admin moze edytowac nazwe, kolor i sklad druzyn (dodawanie/usuwanie/zamiana).
- Edycja dozwolona takze po wpisaniu wynikow meczow.
- Zmiany dotycza kolejnych meczow; historia rozegranych meczow pozostaje spojna (snapshoty w `teams/team_players`).
- Walidacja: kazdy gracz turnieju musi byc przypisany do dokladnie jednej druzyny.

### 2.6 Dodawanie meczu turniejowego i wynik

- W widoku turnieju owner/admin dodaje mecz, wybierajac dwie druzyny turniejowe.
- System tworzy standardowy `match` z `tournament_id` oraz kopie skladow do `teams` i `team_players`.
- Uzytkownik wpisuje wynik (home/away + opcjonalne metadata).
- Mecz pojawia sie w historii turnieju, tabela aktualizuje W/L i roznice bramek.

### 2.7 Zakonczenie turnieju

- Owner/admin wykonuje `completeTournament`.
- Use case zmienia status turnieju na `completed`.
- W tym kroku liczona i zapisywana jest finalna zmiana rankingow graczy turnieju (szczegoly algorytmu do doprecyzowania).

## 3. DB - docelowy model

### 3.1 `tournaments`

Turnieje scoped do squadu.

| Kolumna         | Typ         | Ograniczenia                                          |
| --------------- | ----------- | ----------------------------------------------------- |
| `tournament_id` | UUID        | PK                                                    |
| `squad_id`      | UUID        | NOT NULL; FK -> `squads(squad_id)` ON DELETE CASCADE |
| `name`          | TEXT        | NULLABLE                                              |
| `status`        | TEXT/ENUM   | NOT NULL; np. `drafting`, `active`, `completed`      |
| `created_at`    | TIMESTAMPTZ | NOT NULL DEFAULT now()                                |
| `updated_at`    | TIMESTAMPTZ | NOT NULL DEFAULT now()                                |

Uwagi:
- usuwamy `teams_expected_count`.
- dodajemy RLS zgodne z matches.

### 3.2 `tournament_teams`

Tozsamosci druzyn turniejowych (edytowalne nazwy/kolory).

| Kolumna              | Typ         | Ograniczenia                                                    |
| -------------------- | ----------- | --------------------------------------------------------------- |
| `tournament_team_id` | UUID        | PK                                                              |
| `tournament_id`      | UUID        | NOT NULL; FK -> `tournaments(tournament_id)` ON DELETE CASCADE |
| `name`               | TEXT        | NULLABLE                                                        |
| `color`              | TEXT        | NULLABLE                                                        |
| `created_at`         | TIMESTAMPTZ | NOT NULL DEFAULT now()                                          |

### 3.3 `tournament_team_players`

Sklady druzyn turniejowych.

| Kolumna              | Typ  | Ograniczenia                                                                 |
| -------------------- | ---- | ---------------------------------------------------------------------------- |
| `tournament_team_id` | UUID | NOT NULL; FK -> `tournament_teams(tournament_team_id)` ON DELETE CASCADE    |
| `tournament_id`      | UUID | NOT NULL; FK -> `tournaments(tournament_id)` ON DELETE CASCADE              |
| `player_id`          | UUID | NOT NULL; FK -> `players(player_id)` ON DELETE CASCADE                      |

Klucze/unikalnosci:
- PK `(tournament_team_id, player_id)`.
- UNIQUE `(tournament_id, player_id)` - gracz moze byc tylko w jednej druzynie.

### 3.4 `tournament_drafts`

Metadane draftow turniejowych (oddzielnie od match draftow).

| Kolumna            | Typ         | Ograniczenia                                                                  |
| ------------------ | ----------- | ----------------------------------------------------------------------------- |
| `tournament_draft_id` | UUID     | PK                                                                            |
| `squad_id`         | UUID        | NOT NULL; FK -> `squads(squad_id)` ON DELETE CASCADE                         |
| `tournament_id`    | UUID        | NOT NULL; FK -> `tournaments(tournament_id)` ON DELETE CASCADE               |
| `status`           | TEXT        | NOT NULL; `completed` lub `error`                                             |
| `team_count`       | SMALLINT    | NOT NULL; CHECK `between 2 and 4`                                             |
| `proposals_count`  | INTEGER     | NOT NULL DEFAULT 0                                                             |
| `error_message`    | TEXT        | NULLABLE                                                                      |
| `created_at`       | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                        |
| `updated_at`       | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                        |

Uwagi:
- brak unikalnosci po `tournament_id`, bo chcemy historię wielu draftow/propozycji.
- turniej moze wskazywac zaakceptowany draft przez dodatkowe pole `accepted_tournament_draft_id` lub przez latest accepted event.

### 3.5 `tournament_draft_payloads`

Ciezki payload draftu turniejowego.

| Kolumna               | Typ         | Ograniczenia                                                            |
| --------------------- | ----------- | ----------------------------------------------------------------------- |
| `tournament_draft_id` | UUID        | PK; FK -> `tournament_drafts(tournament_draft_id)` ON DELETE CASCADE   |
| `proposals`           | JSONB       | NOT NULL DEFAULT `[]`; CHECK array                                     |
| `win_rate_matrix`     | JSONB       | NOT NULL DEFAULT `{}`; CHECK object                                    |
| `created_at`          | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                 |
| `updated_at`          | TIMESTAMPTZ | NOT NULL DEFAULT now()                                                 |

### 3.6 Ranking turniejowy (rozszerzenie `ranking_history`)

Wymaganie: wpis rankingowy powstaje tylko raz przy tworzeniu turnieju i nie tworzymy wpisow rankingowych przy kazdym meczu turniejowym.

Zamiast osobnej tabeli dodajemy opcjonalna kolumne:

- `ranking_history.tournament_id UUID NULL`
  - FK -> `tournaments(tournament_id)` (rekomendacja: `ON DELETE SET NULL`),
  - indeks po `tournament_id`,
  - wpis turniejowy ma `match_id = NULL` i `tournament_id != NULL`.

Zastosowanie:
- przy `createTournament` tworzymy po jednym wpisie `ranking_history` dla kazdego gracza turnieju (snapshot startowy),
- podczas turnieju UI meczow turniejowych czyta ranking bazowy z tych wpisow,
- `completeTournament` wylicza finalne delty i aktualizuje te same wpisy + globalny ranking graczy.

## 4. Domena i kontrakty

### 4.1 Encja `Tournament`

- `id`
- `squadId`
- `name`
- `status`
- `createdAt`
- `updatedAt`
- `List<TournamentTeam>? teams`
- `List<Match>? matches`

### 4.2 `TournamentsRepository` (docelowo)

- `getTournaments(squadId)`
- `getTournament(tournamentId)`
- `createTournament(...)`
- `updateTournament(...)`
- `deleteTournament(tournamentId)`
- `updateTournamentTeams(tournamentId, teams)`
- `completeTournament(tournamentId)`

### 4.3 `TournamentDraftRepository` (nowy)

- `createOrUpdateTournamentDraft(...)`
- `getTournamentDrafts(tournamentId)`
- `getTournamentDraft(tournamentDraftId)`
- `acceptTournamentDraft(tournamentId, tournamentDraftId)`

### 4.4 `TournamentMatch` use case (nowy)

`CreateTournamentMatchUseCase`:
- input: `tournamentId`, `homeTournamentTeamId`, `awayTournamentTeamId`.
- tworzy `matches` z `tournament_id`.
- tworzy snapshoty w `teams` + `team_players` jako kopie aktualnych skladow z `tournament_team_players`.
- nie tworzy nowych ranking entries dla tego meczu.

## 5. Application use cases (MVP full flow)

- `CreateTournamentUseCase`:
  - tworzy turniej (`status=drafting`),
  - inicjalizuje jednorazowe wpisy `ranking_history` z `tournament_id` dla wybranych graczy.

- `GetTournamentsUseCase`:
  - lista turniejow dla squadu (bez ciezkich relacji).

- `GetTournamentUseCase`:
  - detal turnieju: teams + matches + tabela.

- `GetTournamentDraftUseCase`:
  - pobiera ostatni draft turnieju lub inicjuje nowy.

- `SaveTournamentDraftUseCase`:
  - zapisuje draft completed/error do `tournament_drafts` + payload.
  - payload przechowuje dane potrzebne do odtworzenia relacji i propozycji.

- `AcceptTournamentDraftUseCase`:
  - mapuje wybrana propozycje do `tournament_teams` + `tournament_team_players`,
  - waliduje pelne i rozlaczne przypisanie wszystkich graczy,
  - ustawia `status=active`.

- `UpdateTournamentTeamsUseCase`:
  - edycja nazw, kolorow i skladow.

- `CreateTournamentMatchUseCase`:
  - opisany wyzej; snapshot do standardowych tabel meczowych.

- `CompleteTournamentUseCase`:
  - `status=completed`,
  - liczy finalna zmiane rankingow na podstawie tabeli turniejowej (algorytm do doprecyzowania),
  - aktualizuje wpisy `ranking_history` z danym `tournament_id` i ranking globalny graczy.

## 6. Policy wyboru algorytmu draftu (do domeny)

Wprowadzamy jawna polityke progow, zalezna od liczby druzyn:

- `teamCount = 2`: `combinatory` dla `n < 20`, `greedy` dla `n >= 20`.
- `teamCount = 3`: `combinatory` dla `n < 12`, `greedy` dla `n >= 12`.
- `teamCount = 4`: `combinatory` dla `n < 10`, `greedy` dla `n >= 10`.

Rekomendacja implementacyjna:
- nowy komponent domenowy, np. `DraftAlgorithmPolicy.resolve(teamCount, playerCount)`.
- uzycie zarowno w match draft, jak i tournament draft.

## 7. Routing i UI (pelny flow)

Dodajemy trasy:

- `/squads/:squadId/tournaments`
- `/squads/:squadId/tournaments/create`
- `/squads/:squadId/tournaments/:tournamentId/draft/relations`
- `/squads/:squadId/tournaments/:tournamentId/draft/relations/against`
- `/squads/:squadId/tournaments/:tournamentId/draft`
- `/squads/:squadId/tournaments/:tournamentId`
- `/squads/:squadId/tournaments/:tournamentId/teams`
- `/squads/:squadId/tournaments/:tournamentId/drafts/:tournamentDraftId` (podglad propozycji)

UI:
- lista turniejow,
- kreator turnieju (wybor graczy + liczba druzyn),
- ekran relacji `Razem`,
- ekran relacji `Przeciwko sobie`,
- podglad i akceptacja draftu,
- detal turnieju z tabela (W/L + GD),
- widok teams z edycja skladow i metadanych.

## 8. Integracja z match details

Jesli `match.tournament_id != null`:
- ukrywamy akcje `Redraft` i `Rematch`,
- pozostawiamy podglad i edycje wyniku wg uprawnien,
- sklad meczu pozostaje snapshotem historycznym.

## 9. Otwarte punkty (do doprecyzowania w implementacji)

- Formula finalnej zmiany rankingu w `CompleteTournamentUseCase` (jak mapujemy tabele turniejowa na delty rankingowe).
- Czy statusy turnieju rozszerzamy o `cancelled/archived` juz w MVP, czy tylko `drafting/active/completed`.
