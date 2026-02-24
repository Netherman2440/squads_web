# stats - dokumentacja feature (stan aktualny)

Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `stats` w aktualnym kodzie nie istnieje jako osobny modul (`app/lib/features/stats`), tylko jako przekrojowa funkcjonalnosc w:
- `features/squads` (statystyki skladu),
- `features/players` (statystyki zawodnika + head-to-head),
- `features/matches` i `features/draft` (prawdopodobienstwo wygranej).

Zakres biznesowy:
- pokazanie agregatow dla skladu i zawodnika,
- porownania zawodnik-vs-zawodnik,
- estymacja szans wygranej na poziomie meczu i draftu.

Zakres techniczny:
- dane liczone glownie po stronie SQL RPC w Supabase,
- odczyt przez repozytoria i use case w Flutterze,
- prezentacja w stronach `SquadStatsPage`, `PlayerStatsPage`, `MatchDetailsPage`, `DraftResultsPage`.

Ten dokument jest source of truth dla metryk i kontraktow stats. Inne feature opisuja stats tylko jako punkty styku.

## 2. Co jest zaimplementowane
- Statystyki skladu (`/squads/:squadId/stats`):
  - `SquadStatsPage` pobiera dane przez `squadStatsProvider` -> `GetSquadStatsUseCase` -> `SquadRepository.getSquadStats` -> RPC `get_squad_stats`.
  - Renderowane kafelki: `Top player`, `Rising star`, `Matches`, `Total goals`, `Home goals`, `Away goals`, `Avg goals per match`, `Avg score (home : away)`, `Players`, `Avg player score`.
- Statystyki zawodnika (`/squads/:squadId/players/:playerId/stats`):
  - `PlayerStatsPage` pobiera rownolegle:
    - agregaty z RPC `get_player_stats`,
    - relacje z RPC `get_player_head_to_head_stats`.
  - Head-to-head jest prezentowane jako sortowalna tabela (`PlayerHeadToHeadTable`) z kolumnami dla relacji "razem" i "przeciwko".
- Probabilistyka meczu:
  - w DB istnieja funkcje `get_match_win_probability` i `refresh_match_win_probability`,
  - wynik jest zapisywany w `matches.home_win_prob`,
  - `MatchDetailsPage` pokazuje `ProbabilitySlider`, gdy `homeWinProbability != null`.
- Probabilistyka draftu:
  - `DraftSessionNotifier` pobiera macierz przez `GetPlayerPairWinRatesUseCase` -> RPC `get_player_pair_win_rates`,
  - oblicza lokalnie `homeWinProbability` dla propozycji draftu i pokazuje je w `DraftResultsPage`.

## 3. Routing
Zdefiniowane trasy:
- `/squads/:squadId/stats` (`AppRoute.squadStats`) -> `SquadStatsPage`
- `/squads/:squadId/players/:playerId/stats` (`AppRoute.playerStats`) -> `PlayerStatsPage`

Wejscia na trasy:
- `SquadHomePage`: tile `Stats` otwiera `AppRoute.squadStats`,
- `RootShell`: pozycja bocznej nawigacji `Stats` prowadzi do `/squads/$squadId/stats`,
- `PlayerDetailsPage`: tab `Stats` otwiera `AppRoute.playerStats`.

UI powiazane (bez osobnej trasy stats):
- `MatchDetailsPage` pokazuje suwak prawdopodobienstwa meczu,
- `DraftResultsPage` pokazuje suwak prawdopodobienstwa dla propozycji draftu.

## 4. DB i RLS (zbiorczo)
- Tabele i kluczowe pola:
  - `players`: `base_score`, `score`, `squad_id`, `name`.
  - `matches`: `home_score`, `away_score`, `played_at`, `squad_id`, `home_win_prob`.
  - `teams`: `match_id`, `side`.
  - `team_players`: relacja `match_id` + `team_id` + `player_id`.
- Istotne constraints/indeksy:
  - `players`: `players_squad_name_unique`, zakresy `base_score` i `score` (`0..100`), indeks `players_squad_idx`.
  - `matches`: indeks `matches_squad_played_at_idx`; `home_win_prob` ma `matches_home_win_prob_range_chk` (`0..1` lub `null`).
  - `teams`: `teams_match_side_unique` (jedno `home` i jedno `away` na mecz), indeks `teams_match_idx`.
  - `team_players`: `team_players_unique_player_per_match`, FK `team_players_player_fk` jest `on delete cascade` (migracja `20251202110000`), indeksy `team_players_player_idx` i `team_players_team_idx`.
- RPC/funkcje SQL:
  - `get_squad_stats(p_squad_id uuid)`:
    - zwraca top/worst/rising player (jsonb) + agregaty meczowe i graczy,
    - liczy tylko mecze z kompletnym wynikiem (`home_score` i `away_score` nie-null).
  - `get_player_stats(p_player_id uuid)`:
    - zwraca ranking bazowy/aktualny, W/D/L, streaki, gole i srednie,
    - streaki liczone po `played_at desc`, fallback `created_at`.
  - `get_player_head_to_head_stats(p_player_id uuid)`:
    - statystyki razem i przeciwko dla kazdego przeciwnika,
    - tylko mecze z kompletnym wynikiem.
  - `get_player_pair_win_rates(p_player_ids uuid[])`:
    - macierz pairwise; wygrana=1, remis=0.5, porazka=0; fallback `0.5`.
  - `get_match_win_probability(p_match_id uuid)` i `refresh_match_win_probability(p_match_id uuid)`:
    - estymacja i zapis `home_win_prob` dla meczu.
- RLS:
  - odczyt (`select`) na `players`, `matches`, `teams`, `team_players` jest dla czlonkow skladu lub dla skladow publicznych,
  - modyfikacja (`insert/update/delete`) ograniczona do `owner/admin`,
  - polityki dla tych tabel opieraja sie na relacji `user_squads`; pomocnicze funkcje `is_squad_member/is_squad_admin/is_squad_owner` sa zdefiniowane i wykorzystywane m.in. w politykach `squads`.

## 5. Architektura
### 5.1 Domain
- `features/squads/domain/entities/squad_stats.dart`
- `features/players/domain/entities/player_stats.dart`
- `features/players/domain/entities/player_head_to_head_stat.dart`
- `features/matches/domain/entities/match.dart` (`homeWinProbability`, `Probability`)
- `features/draft/domain/entities/head_to_head_win_rate.dart`

### 5.2 Application
- Squad:
  - `GetSquadStatsUseCase`
- Player:
  - `GetPlayerStatsUseCase`
  - `GetPlayerHeadToHeadStatsUseCase`
- Draft:
  - `GetPlayerPairWinRatesUseCase`
- Matches (punkty zapisu prawdopodobienstwa):
  - `CreateMatchUseCase` -> `refreshMatchWinProbability`
  - `UpdateMatchTeamsUseCase` -> `refreshMatchWinProbability`

### 5.3 Infrastructure
- `SupabaseSquadRepository.getSquadStats` -> RPC `get_squad_stats`
- `SupabasePlayerRepository.getPlayerStats` -> RPC `get_player_stats`
- `SupabasePlayerRepository.getPlayerHeadToHeadStats` -> RPC `get_player_head_to_head_stats`
- `SupabaseDraftStatsRepository.getPlayerPairWinRates` -> RPC `get_player_pair_win_rates`
- `SupabaseMatchRepository.refreshMatchWinProbability` -> RPC `refresh_match_win_probability`

### 5.4 Presentation
- Squad stats:
  - `squad_stats_provider.dart`
  - `squad_stats_page.dart`
  - `stat_tile.dart`
- Player stats:
  - `player_stats_provider.dart`
  - `player_stats_page.dart`
  - `player_head_to_head_table.dart`
- Probability UI:
  - `match_details_page.dart` (`ProbabilitySlider` dla meczu)
  - `draft_results_page.dart` (`ProbabilitySlider` dla draftu)

## 6. Integracje / punkty styku
- `stats` <-> `squads`:
  - strona statystyk skladu jest implementowana calkowicie w module `squads`.
  - Punkty styku po stronie consumer: [squads.md](./squads.md).
- `stats` <-> `players`:
  - statystyki zawodnika i head-to-head sa implementowane w module `players`.
  - Punkty styku po stronie consumer: [players.md](./players.md).
- `stats` <-> `matches`:
  - encja `Match` i DTO niosa `home_win_prob`,
  - `MatchDetailsPage` pokazuje wynik estymacji.
  - Punkty styku po stronie consumer: [matches.md](./matches.md).
- `stats` <-> `draft`:
  - draft pobiera pairwise win-rate i buduje probabilistyczny podglad dla proponowanych druzyn.
  - Punkty styku po stronie consumer: [draft.md](./draft.md).
- `stats` <-> `ranking_history`:
  - zmiany wynikow meczow aktualizuja rankingi graczy; to bezposrednio wplywa na `top_player`, `rising_star`, `avg_player_score` i statystyki zawodnika.
  - Szczegoly aktualizacji rankingu sa utrzymywane w [ranking_history.md](./ranking_history.md).

## 7. Szybka mapa plikow
- Najwazniejsze pliki (Flutter):
  - `app/lib/features/squads/presentation/pages/squad_stats_page.dart`
  - `app/lib/features/squads/presentation/state/squad_stats_provider.dart`
  - `app/lib/features/squads/domain/entities/squad_stats.dart`
  - `app/lib/features/squads/application/get_squad_stats_use_case.dart`
  - `app/lib/features/squads/infrastructure/repositories/supabase_squad_repository.dart`
  - `app/lib/features/players/presentation/pages/player_stats_page.dart`
  - `app/lib/features/players/presentation/state/player_stats_provider.dart`
  - `app/lib/features/players/presentation/widgets/player_head_to_head_table.dart`
  - `app/lib/features/players/domain/entities/player_stats.dart`
  - `app/lib/features/players/domain/entities/player_head_to_head_stat.dart`
  - `app/lib/features/players/infrastructure/repositories/supabase_player_repository.dart`
  - `app/lib/features/matches/domain/entities/match.dart`
  - `app/lib/features/matches/infrastructure/repositories/supabase_match_repository.dart`
  - `app/lib/core/app_router.dart`
  - `app/lib/core/root_shell.dart`
- Najwazniejsze migracje SQL:
  - `supabase/migrations/20251202120000_add_player_head_to_head_stats_function.sql`
  - `supabase/migrations/20251202121000_add_match_win_probability_function.sql`
  - `supabase/migrations/20251202122000_add_home_win_prob_to_matches.sql`
  - `supabase/migrations/20251202123000_add_player_pair_win_rates_function.sql`
  - `supabase/migrations/20251202124000_add_squad_stats_function.sql`
  - `supabase/migrations/20251202125000_add_player_stats_function.sql`
  - `supabase/migrations/20251201090400_create_players_table.sql`
  - `supabase/migrations/20251201090600_create_matches_table.sql`
  - `supabase/migrations/20251201090700_create_teams_table.sql`
  - `supabase/migrations/20251201090800_create_team_players_table.sql`
  - `supabase/migrations/20251201090300_create_user_squads_table.sql`
  - `supabase/migrations/20251202110000_update_team_players_player_fk_cascade.sql`

## 8. Ograniczenia i status
- Brak osobnego modulu `features/stats`; logika jest rozproszona miedzy `squads`, `players`, `matches`, `draft`.
- `SquadStatsPage` nie renderuje `worst_player`, mimo ze pole istnieje w `SquadStats` i zwraca je RPC `get_squad_stats`.
- `StatTile` dla typu `Player` pokazuje tylko `name`; UI nie pokazuje rankingu przy `top_player/worst_player/rising_star`.
- Brak testow jednostkowych/widgetowych dla `player_stats_provider`, `PlayerStatsPage` i mapowania head-to-head; obecne testy stats obejmuja tylko `GetSquadStatsUseCase` i `squadStatsProvider`.
- Brak testow SQL (`supabase/tests`) dla funkcji stats/RPC i ich zachowania pod RLS.
- `refresh_match_win_probability` jest wywolywane przy tworzeniu meczu i zmianie skladu meczu, ale nie ma centralnego mechanizmu odswiezania po zmianie wynikow innych meczow w squadzie.
