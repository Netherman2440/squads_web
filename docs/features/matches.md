# Matches - dokumentacja feature (stan aktualny)

Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `matches` odpowiada za:
- liste meczow skladu,
- szczegoly meczu (sklady, wynik, kolory, nazwy druzyn, prawdopodobienstwo wygranej),
- tworzenie i modyfikacje skladow meczu przez flow draftu,
- aktualizacje wyniku i aktualizacje rankingu graczy,
- usuwanie meczu i tworzenie rewanzu.

Zakres obejmuje `app/lib/features/matches` oraz integracje z `draft`, `players`, `squads` i migracjami Supabase.

## 2. Co jest zaimplementowane
- `SquadMatchesPage` wyswietla mecze skladu i odswiezanie listy (`squadMatchesProvider`).
- Dla `owner/admin` widoczny jest przycisk `+`, ktory prowadzi do flow draftu.
- `MatchDetailsPage` obsluguje:
  - widok skladu home/away,
  - przejscie do szczegolow gracza po kliknieciu na zawodnika,
  - edycje nazw i kolorow druzyn,
  - edycje skladow przez drag-and-drop (przenoszenie i usuwanie zawodnikow),
  - aktualizacje wyniku,
  - redraft, rewanz i usuwanie meczu.
- Aktualizacja wyniku (`UpdateMatchScoreUseCase`) obsluguje logike rankingu:
  - odczyt ustawien rankingu skladu (`ranking_update`, `ranking_multiplier`, `use_experience_factor`),
  - aktualizacje `ranking_history.change`,
  - aktualizacje `players.score` z clampem do `0..100`.
- Tworzenie meczu (`CreateMatchUseCase`) tworzy rekord meczu, zespoly, sklady i wpisy `ranking_history` dla wskazanych graczy.
- Aktualizacja skladow (`UpdateMatchTeamsUseCase`) synchronizuje `team_players`, dopisuje/usuwa wpisy `ranking_history` i odswieza `home_win_prob`.
- `DeleteMatchUseCase` usuwa powiazane wpisy rankingowe (z rollbackiem score) i dopiero potem usuwa mecz.
- `RematchUseCase` tworzy nowy mecz z zamienionymi stronami (stary away -> nowy home).

## 3. Routing
Trasy zdefiniowane w `app/lib/core/app_router.dart`:
- `/squads/:squadId/matches` -> `SquadMatchesPage`
- `/squads/:squadId/matches/:matchId` -> `MatchDetailsPage`
- `/squads/:squadId/matches/draft` -> `DraftSelectionPage` (route nazwany `draftSelection`)
- `/squads/:squadId/matches/create` -> `DraftSelectionPage` (route nazwany `draftCreate`)
- `/squads/:squadId/matches/:matchId/draft` -> `DraftResultsPage` (route nazwany `matchDraft`)

Wejscia do feature:
- kafel `Matches` w `SquadHomePage`,
- `Quick actions -> Add match` w `SquadShellPage`,
- lista meczow gracza (`PlayerMatchesPage`) korzysta z `MatchTile` i prowadzi do `MatchDetailsPage`.

Nawigacja z feature:
- z detalu meczu do detalu gracza: `/squads/:squadId/players/:playerId`,
- z flow draftu do detalu meczu po zapisaniu.

## 4. DB i RLS (zbiorczo)
Tabele i pola kluczowe:
- `matches`
  - `match_id` (PK), `squad_id` (FK), `tournament_id` (FK nullable),
  - `score_type`, `home_score`, `away_score`, `score_meta`, `played_at`, `created_at`,
  - `home_win_prob` (nullable, zakres `0..1`).
- `teams`
  - `team_id` (PK), `match_id` (FK), `side` (`home|away`), `name`, `color`,
  - `UNIQUE (match_id, side)`.
- `team_players`
  - PK `(match_id, team_id, player_id)`,
  - `UNIQUE (match_id, player_id)` (gracz tylko raz w meczu),
  - FK do `players` z `on delete cascade` (migracja `20251202110000`).
- `ranking_history` (uzywane przez flow meczu i score)
  - `player_id`, `match_id`, `ranking`, `change`,
  - unikalnosc `(player_id, match_id)` dla `match_id is not null`.
- `drafts` i `draft_payloads`
  - persystencja propozycji draftu powiazanych 1:1 z meczem (`UNIQUE (match_id)`).

Istotne indeksy/constrainty:
- `matches_squad_played_at_idx` (sortowanie listy meczow po `played_at`, potem `created_at`),
- `teams_match_side_unique`,
- `team_players_unique_player_per_match`,
- `matches_home_win_prob_range_chk`.

Funkcje SQL (RPC) uzywane przez feature:
- `refresh_match_win_probability(p_match_id uuid)` - zapisywanie `home_win_prob` do `matches`,
- `get_match_win_probability(p_match_id uuid)` - estymacja na bazie historycznych head-to-head.

RLS (kto czyta / kto modyfikuje):
- `matches`, `teams`, `team_players`, `ranking_history`, `drafts`, `draft_payloads`:
  - `SELECT`: czlonkowie skladu (`owner/admin/member`) lub widok publicznego skladu,
  - `INSERT/UPDATE/DELETE`: `owner/admin`.
- Walidacje polityk wymuszaja tez spojnosc gracza z skladem meczu (np. `team_players`, `ranking_history`).

## 5. Architektura
### 5.1 Domain
- Encje:
  - `match.dart`
  - `team.dart`
  - `match_enums.dart` (`MatchScoreType`, `Side`)
- Repozytoria:
  - `match_repository.dart`
  - `team_repository.dart`

### 5.2 Application
- Odczyt:
  - `get_squad_matches_usecase.dart`
  - `get_match_usecase.dart`
- Modyfikacje:
  - `create_match_usecase.dart`
  - `update_match_teams_usecase.dart`
  - `update_match_team_usecase.dart`
  - `update_match_score_usecase.dart`
  - `delete_match_usecase.dart`
  - `rematch_usecase.dart`
- DTO:
  - `match_details_dto.dart`
  - `team_dto.dart`
  - `player_dto.dart`

### 5.3 Infrastructure
- `SupabaseMatchRepository`:
  - lista meczow z `matches + teams`,
  - odczyt pojedynczego meczu (`matches`),
  - tworzenie/usuwanie meczu,
  - aktualizacja wyniku,
  - RPC `refresh_match_win_probability`.
- `SupabaseTeamRepository`:
  - odczyt zespolow i zawodnikow dla meczu (`teams`, `team_players`, `players`),
  - mapowanie rankingu historycznego z `ranking_history` na ranking wyswietlany w detalu meczu,
  - tworzenie/aktualizacja zespolow i skladow.

### 5.4 Presentation
- Kontrolery:
  - `squad_matches_notifier.dart`
  - `match_details_notifier.dart`
  - `create_match_controller.dart`
- Strony:
  - `squad_matches_page.dart`
  - `match_details_page.dart`
- Widgety:
  - `match_tile.dart`
  - `match_player_tile.dart`

## 6. Integracje / punkty styku
- `draft`:
  - `DraftSelectionPage` i `DraftResultsPage` obsluguja tworzenie/aktualizacje skladow meczu,
  - zapis/odczyt propozycji draftu w `drafts` + `draft_payloads`.
- `players`:
  - `CreateMatchUseCase`, `UpdateMatchTeamsUseCase`, `UpdateMatchScoreUseCase`, `DeleteMatchUseCase`
    korzystaja z `PlayerRepository` i `RankingRepository`,
  - `GetPlayerMatchesUseCase` korzysta z `MatchRepository.getMatches`.
- `squads`:
  - uprawnienia UI (`SquadRole`) z `squadDetailProvider`,
  - ustawienia rankingu skladu (`GetSquadUseCase`) steruja logika `UpdateMatchScoreUseCase`.
- `core`:
  - `team_ranking.dart` (efektywny rating druzyny),
  - `probability_slider.dart` (UI prawdopodobienstwa wygranej).

## 7. Szybka mapa plikow
Najwazniejsze pliki w feature:
- `app/lib/features/matches/domain/entities/match.dart`
- `app/lib/features/matches/domain/entities/team.dart`
- `app/lib/features/matches/domain/repositories/match_repository.dart`
- `app/lib/features/matches/domain/repositories/team_repository.dart`
- `app/lib/features/matches/application/usecases/create_match_usecase.dart`
- `app/lib/features/matches/application/usecases/update_match_score_usecase.dart`
- `app/lib/features/matches/application/usecases/update_match_teams_usecase.dart`
- `app/lib/features/matches/application/usecases/delete_match_usecase.dart`
- `app/lib/features/matches/application/usecases/rematch_usecase.dart`
- `app/lib/features/matches/infrastructure/repositories/supabase_match_repository.dart`
- `app/lib/features/matches/infrastructure/repositories/supabase_team_repository.dart`
- `app/lib/features/matches/presentation/pages/squad_matches_page.dart`
- `app/lib/features/matches/presentation/pages/match_details_page.dart`

Najwazniejsze pliki poza feature:
- `app/lib/core/app_router.dart`
- `app/lib/features/draft/presentation/pages/draft_selection_page.dart`
- `app/lib/features/draft/presentation/pages/draft_results_page.dart`
- `app/lib/features/players/infrastructure/repositories/supabase_ranking_repository.dart`
- `supabase/migrations/20251201090600_create_matches_table.sql`
- `supabase/migrations/20251201090700_create_teams_table.sql`
- `supabase/migrations/20251201090800_create_team_players_table.sql`
- `supabase/migrations/20251201090900_create_ranking_history_table.sql`
- `supabase/migrations/20251202110000_update_team_players_player_fk_cascade.sql`
- `supabase/migrations/20251202121000_add_match_win_probability_function.sql`
- `supabase/migrations/20251202122000_add_home_win_prob_to_matches.sql`
- `supabase/migrations/20260219110000_create_drafts_tables.sql`

## 8. Ograniczenia i status
- Brak dedykowanych testow `flutter_test` dla feature `matches` w `app/test`.
- UI pozwala wejsc w edycje skladow takze dla meczu z wynikiem, ale zapis jest blokowany w `UpdateMatchTeamsUseCase` (rzuca blad).
- Flow aktualizacji wyniku nie egzekwuje wprost warunku "brak nowszego meczu z wynikiem" ani warningu nierownych druzyn.
- W UI brak obslugi `score_type`, `score_meta`, `played_at` i `tournament_id` (pola istnieja w DB/modelu).
- Istnieja dwie trasy do `DraftSelectionPage` (`/matches/draft` i `/matches/create`), podczas gdy finalny ekran propozycji to `/matches/:matchId/draft`.
- Dodawanie nowego gracza do istniejacego meczu jest realizowane praktycznie przez redraft/selection, bez osobnego wyszukiwacza na detalu meczu.
