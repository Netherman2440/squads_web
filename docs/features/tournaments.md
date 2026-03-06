# Tournaments - dokumentacja feature (stan aktualny)

Stan na: **6 marca 2026**

## 1. Cel i zakres
Feature `tournaments` odpowiada za:
- liste turniejow w ramach skladu,
- utworzenie turnieju i inicjalizacje snapshotow rankingowych zawodnikow,
- flow draftu druzyn turniejowych (relacje, generowanie, podglad, akceptacja),
- zarzadzanie skladami i metadanymi druzyn turniejowych,
- dodawanie meczow turniejowych i podglad tabeli turnieju,
- zamkniecie i usuniecie turnieju.

Zakres obejmuje `app/lib/features/tournaments` oraz integracje z `draft`, `matches`, `players`, `ranking_history`, `squads` i migracjami Supabase.

## 2. Co jest zaimplementowane

### 2.1 Lista turniejow skladu
Ekran: `SquadTournamentsPage` (`/squads/:squadId/tournaments`)
- lista turniejow (nazwa, status, data utworzenia),
- pull-to-refresh,
- wejscie do detalu turnieju,
- FAB `Utworz turniej` widoczny tylko dla `owner/admin`.

### 2.2 Tworzenie turnieju i snapshot rankingu
Ekran: `CreateTournamentPage` (`/squads/:squadId/tournaments/create`)
- wybor graczy + opcjonalna nazwa turnieju,
- wybor liczby druzyn (`2..4`, domyslnie `3`),
- dwa warianty przejscia:
  - do relacji draftu,
  - bezposrednio do generowania propozycji.

Use case: `CreateTournamentUseCase`
- tworzy rekord `tournaments` ze statusem `drafting`,
- tworzy po jednym wpisie `ranking_history` z `tournament_id` dla kazdego wybranego gracza (snapshot startowy).

### 2.3 Relacje draftu (razem/przeciwko)
Ekrany:
- `TournamentRelationsPage` (`.../draft/relations`),
- `TournamentAgainstRelationsPage` (`.../draft/relations/against`).

Implementacja:
- edycja grup `together` i `against`,
- walidacja reguly (wybrani gracze, brak konfliktow, limity wg `teamCount`) przez `validateDraftGroups`,
- przekazanie relacji do ekranu generowania draftu.

### 2.4 Generowanie i zapis propozycji draftu
Ekran: `TournamentDraftPage` (`.../draft` oraz `.../drafts/:tournamentDraftId`)
- generowanie propozycji draftu dla wybranych graczy,
- polityka algorytmu przez `DraftAlgorithmPolicy`:
  - `teamCount=2`: threshold `20`,
  - `teamCount=3`: threshold `12`,
  - `teamCount=4`: threshold `10`,
- zapis wygenerowanego draftu do `tournament_drafts` i `tournament_draft_payloads`,
- podglad poprzednio zapisanego draftu po `tournamentDraftId`,
- reczna korekta propozycji przez drag-and-drop przed akceptacja.

### 2.5 Akceptacja draftu i aktywacja turnieju
Use case: `AcceptTournamentDraftUseCase`
- pobiera draft, waliduje przynaleznosc do turnieju i status,
- waliduje integralnosc propozycji (kazdy gracz dokladnie raz),
- mapuje propozycje na `tournament_teams` + `tournament_team_players`,
- ustawia `tournaments.status = active`,
- zapisuje `accepted_tournament_draft_id`.

### 2.6 Detal turnieju, tabela i mecze
Ekran: `TournamentDetailsPage` (`/squads/:squadId/tournaments/:tournamentId`)
- widok druzyn (nazwa, kolor, gracze, suma rankingu),
- tabela turniejowa (pkt/M/Z/R/P/RB) liczona z meczow turniejowych,
- lista meczow turniejowych z szybka edycja wyniku,
- podglad propozycji draftu (`accepted_tournament_draft_id` albo ostatni completed draft),
- akcje dla `owner/admin`:
  - `Edytuj druzyny`,
  - `Dodaj mecz` (tylko gdy turniej `active` i sa min. 2 druzyny),
  - `Zakoncz`,
  - `Usun`.

Use case: `CreateTournamentMatchUseCase`
- tworzy standardowy `match` z `tournament_id`,
- kopiuje sklady druzyn turniejowych do `teams` i `team_players`,
- ustawia `score_meta` z `tournament_home_team_id` i `tournament_away_team_id`,
- nie tworzy ranking entries dla meczu (`createRankingEntries=false`).

### 2.7 Edycja druzyn turniejowych
Ekran: `TournamentTeamsPage` (`/squads/:squadId/tournaments/:tournamentId/teams`)
- edycja nazw i kolorow druzyn,
- drag-and-drop zawodnikow miedzy druzynami,
- zapis przez `UpdateTournamentTeamsUseCase` z walidacja:
  - min. 2 druzyny,
  - kazda druzyna ma min. 1 zawodnika,
  - kazdy zawodnik nalezy do dokladnie jednej druzyny,
  - sklad musi pokrywac komplet zawodnikow turnieju.
- `Generuj ponownie` prowadzi do flow draftu dla aktualnie przypisanych graczy.

### 2.8 Zamkniecie i usuniecie turnieju
Use case: `CompleteTournamentUseCase`
- liczy statystyki druzyn z meczow turniejowych,
- wylicza delte rankingu per druzyna:
  - `(wins - losses + goalDifference/10) * rankingMultiplier`,
- opcjonalnie uwzglednia experience factor (dzielenie przez liczbe rozegranych meczow gracza),
- aktualizuje `ranking_history.change` dla wpisow turnieju,
- aktualizuje `players.score`,
- ustawia `status = completed`.

Use case: `DeleteTournamentUseCase`
- usuwa wpisy `ranking_history` powiazane z `tournament_id` (z cofnieciem delty w `players.score`),
- usuwa turniej.

### 2.9 Turnieje z poziomu profilu gracza
Ekran: `PlayerTournamentsPage` (`/squads/:squadId/players/:playerId/tournaments`)
- lista turniejow, w ktorych gracz jest przypisany do skladu turniejowego,
- wejscie do detalu turnieju.

## 3. Routing
Definicje tras sa w `app/lib/core/app_router.dart`:
- `/squads/:squadId/tournaments` -> `SquadTournamentsPage`
- `/squads/:squadId/tournaments/create` -> `CreateTournamentPage`
- `/squads/:squadId/tournaments/:tournamentId/draft/relations` -> `TournamentRelationsPage`
- `/squads/:squadId/tournaments/:tournamentId/draft/relations/against` -> `TournamentAgainstRelationsPage`
- `/squads/:squadId/tournaments/:tournamentId/draft` -> `TournamentDraftPage`
- `/squads/:squadId/tournaments/:tournamentId/teams` -> `TournamentTeamsPage`
- `/squads/:squadId/tournaments/:tournamentId/drafts/:tournamentDraftId` -> `TournamentDraftPage` (podglad konkretnego draftu)
- `/squads/:squadId/tournaments/:tournamentId` -> `TournamentDetailsPage`
- `/squads/:squadId/players/:playerId/tournaments` -> `PlayerTournamentsPage`

Wejscia do feature:
- kafel `Turnieje` w `SquadHomePage`,
- `Szybkie akcje -> Dodaj turniej` w `SquadShellPage`,
- zakladka `Turnieje` w `PlayerDetailsPage`.

## 4. DB i RLS (zbiorczo)
Tabele i pola kluczowe:
- `tournaments`
  - `tournament_id` (PK), `squad_id` (FK), `name`, `status`, `created_at`, `updated_at`,
  - `accepted_tournament_draft_id` (FK -> `tournament_drafts`, `ON DELETE SET NULL`),
  - `status` ograniczony do: `drafting | active | completed`.
- `tournament_teams`
  - `tournament_team_id` (PK), `tournament_id` (FK), `name`, `color`, `created_at`.
- `tournament_team_players`
  - PK `(tournament_team_id, player_id)`,
  - `UNIQUE (tournament_id, player_id)` (zawodnik tylko w jednej druzynie turniejowej),
  - FK do `tournaments`, `tournament_teams`, `players`.
- `tournament_drafts`
  - `status` (`completed | error`), `team_count` (`2..4`), `proposals_count >= 0`,
  - indeksy po `(tournament_id, created_at)` i `(squad_id, created_at)`.
- `tournament_draft_payloads`
  - `proposals` (JSON array),
  - `win_rate_matrix` (JSON object),
  - `rules` (JSON array),
  - `selected_player_ids` (JSON array).
- `ranking_history` (rozszerzenie dla turniejow)
  - `tournament_id` (FK -> `tournaments`, `ON DELETE SET NULL`),
  - check: `num_nonnulls(match_id, tournament_id) <= 1`,
  - unikalnosc `(player_id, tournament_id)` dla nie-null `tournament_id`.

Powiazane tabele meczowe wykorzystywane przez turnieje:
- `matches.tournament_id` (FK -> `tournaments`, `ON DELETE CASCADE`),
- `teams.tournament_id`, `team_players.tournament_id` (powiazanie pomocnicze snapshotu).

RLS (kto czyta / kto modyfikuje):
- `tournaments`, `tournament_teams`, `tournament_team_players`,
  `tournament_drafts`, `tournament_draft_payloads`:
  - `SELECT`: czlonkowie skladu (`owner/admin/member`) lub widok publicznego skladu,
  - `INSERT/UPDATE/DELETE`: `owner/admin`.
- `ranking_history`:
  - polityki insert/update uwzgledniaja tez przypadek `tournament_id`
    (gracz i turniej musza nalezec do tego samego skladu i byc dostepne dla `owner/admin`).

Migracje:
- `supabase/migrations/20251201090500_create_tournaments_table.sql`
- `supabase/migrations/20260225100000_expand_tournaments_feature.sql`
- powiazane kontrakty meczowe/rankingu:
  - `supabase/migrations/20251201090600_create_matches_table.sql`
  - `supabase/migrations/20251201090700_create_teams_table.sql`
  - `supabase/migrations/20251201090800_create_team_players_table.sql`
  - `supabase/migrations/20251201090900_create_ranking_history_table.sql`

## 5. Architektura
### 5.1 Domain
- Encje:
  - `tournament.dart`
  - `tournament_status.dart`
  - `tournament_team.dart`
  - `tournament_draft.dart`
- Repozytoria:
  - `tournament_repository.dart`
  - `tournament_draft_repository.dart`

### 5.2 Application
- Odczyt:
  - `get_tournaments_usecase.dart`
  - `get_tournament_usecase.dart`
  - `get_tournament_draft_usecase.dart`
- Modyfikacje:
  - `create_tournament_usecase.dart`
  - `save_tournament_draft_usecase.dart`
  - `accept_tournament_draft_usecase.dart`
  - `update_tournament_teams_usecase.dart`
  - `create_tournament_match_usecase.dart`
  - `complete_tournament_usecase.dart`
  - `delete_tournament_usecase.dart`
- DTO i logika tabeli:
  - `tournament_details_dto.dart`
  - `tournament_standings_calculator.dart`

### 5.3 Infrastructure
- `SupabaseTournamentRepository`:
  - CRUD `tournaments`,
  - odczyt i upsert skladow `tournament_teams` + `tournament_team_players`,
  - odczyt meczow turniejowych z `matches` (+ `teams`).
- `SupabaseTournamentDraftRepository`:
  - zapis `tournament_drafts` i `tournament_draft_payloads`,
  - odczyt draftu po id i latest draft.
- Providers:
  - `infrastructure/repositories/providers.dart`

### 5.4 Presentation
- Strony:
  - `squad_tournaments_page.dart`
  - `create_tournament_page.dart`
  - `tournament_relations_page.dart`
  - `tournament_against_relations_page.dart`
  - `tournament_draft_page.dart`
  - `tournament_details_page.dart`
  - `tournament_teams_page.dart`
- Stan:
  - `presentation/state/tournament_providers.dart` (lista/detal/realtime ticki)
  - `presentation/state/tournament_draft_helpers.dart`

## 6. Integracje / punkty styku
- `draft`:
  - `CreateDraftUseCase` (combinatory/greedy),
  - `GetPlayerPairWinRatesUseCase`,
  - `DraftAlgorithmPolicy`,
  - wspoldzielone encje `Draft`, `DraftRule` i widgety relacji.
- `matches`:
  - tworzenie meczow turniejowych przez `CreateMatchUseCase` z `tournament_id`,
  - aktualizacja wyniku przez `UpdateMatchScoreUseCase`,
  - `MatchDetailsPage` ukrywa `Wylosuj jeszcze raz` i `Rewanz` dla meczow z `tournament_id != null`.
- `players` i `ranking_history`:
  - snapshot rankingu turnieju (`createTournamentRankingEntry`),
  - finalizacja i rollback rankingu (`updateTournamentRankingChange`, `deleteTournamentRankingEntry`),
  - lista turniejow gracza przez `GetPlayerTournamentsUseCase`.
- `squads`:
  - RBAC w UI na podstawie `squadDetailProvider` (`owner/admin`),
  - ustawienia rankingu skladu (`GetSquadUseCase`) uzywane przy finalizacji turnieju.

## 7. Szybka mapa plikow
Najwazniejsze pliki w feature:
- `app/lib/features/tournaments/domain/entities/tournament.dart`
- `app/lib/features/tournaments/domain/repositories/tournament_repository.dart`
- `app/lib/features/tournaments/domain/repositories/tournament_draft_repository.dart`
- `app/lib/features/tournaments/application/usecases/create_tournament_usecase.dart`
- `app/lib/features/tournaments/application/usecases/accept_tournament_draft_usecase.dart`
- `app/lib/features/tournaments/application/usecases/update_tournament_teams_usecase.dart`
- `app/lib/features/tournaments/application/usecases/create_tournament_match_usecase.dart`
- `app/lib/features/tournaments/application/usecases/complete_tournament_usecase.dart`
- `app/lib/features/tournaments/infrastructure/repositories/supabase_tournament_repository.dart`
- `app/lib/features/tournaments/infrastructure/repositories/supabase_tournament_draft_repository.dart`
- `app/lib/features/tournaments/presentation/pages/tournament_details_page.dart`
- `app/lib/features/tournaments/presentation/pages/tournament_draft_page.dart`
- `app/lib/features/tournaments/presentation/pages/tournament_teams_page.dart`

Najwazniejsze pliki poza feature:
- `app/lib/core/app_router.dart`
- `app/lib/features/draft/domain/services/draft_algorithm_policy.dart`
- `app/lib/features/matches/application/usecases/create_match_usecase.dart`
- `app/lib/features/matches/presentation/pages/match_details_page.dart`
- `app/lib/features/players/infrastructure/repositories/supabase_ranking_repository.dart`
- `supabase/migrations/20251201090500_create_tournaments_table.sql`
- `supabase/migrations/20260225100000_expand_tournaments_feature.sql`

## 8. Ograniczenia i status
- Brak dedykowanych testow `flutter_test` dla feature `tournaments` w `app/test`.
- `SaveTournamentDraftUseCase.executeError` i zapis draftu `status=error` sa zaimplementowane, ale aktualny flow `TournamentDraftPage` nie wywoluje tej sciezki.
- `GetPlayerTournamentsUseCase` wykonuje odczyt czlonkostwa per turniej (`getTournamentPlayerIds` dla kazdego rekordu), co daje koszt typu N+1 dla duzej liczby turniejow.
- `TournamentTeamsPage -> Generuj ponownie` zawsze startuje bez zapisanych relacji draftu (puste `draftRules`).
