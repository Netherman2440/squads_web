# Draft - dokumentacja feature (stan aktualny)

Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `draft` odpowiada za:
- wybor puli zawodnikow do losowania skladu,
- wygenerowanie i przeglad propozycji podzialu skladu,
- manualne przesuwanie zawodnikow miedzy stronami draftu,
- utworzenie lub aktualizacje meczu na bazie wybranej propozycji,
- zapis/odczyt payloadu draftu powiazanego z meczem.

Zakres obejmuje warstwy `domain`, `application`, `infrastructure` i `presentation` w `app/lib/features/draft` oraz tabele `drafts`/`draft_payloads` w Supabase.

Ten dokument jest source of truth dla flow draftu, algorytmow i persystencji payloadu draftu. W `matches.md` draft jest opisywany tylko przez punkty styku.

## 2. Co jest zaimplementowane

### 2.1 Wybieranie zawodnikow do draftu
Ekran: `DraftSelectionPage`
- laduje zawodnikow skladu przez `GetSquadPlayersUseCase`,
- pokazuje dwie listy: `Selected players` i `Available players`,
- obsluguje wyszukiwarke po nazwie i czyszczenie selekcji,
- pozwala przelaczac tryb `Gra ze zmianami` (`playWithSubstitute`),
- uruchamia draft od minimum 2 wybranych zawodnikow.

### 2.2 Tworzenie meczu przed generowaniem draftu
W `DraftSelectionPage`:
- gdy nie ma `matchId`, najpierw wywolywany jest `CreateMatchController.createMatch` z pustymi skladami,
- do meczu zapisywane sa `rankingHistoryPlayerIds` (wybrane ID graczy),
- po sukcesie nastepuje przejscie do ekranu wynikow draftu (`matchDraft`) z `matchId`.

### 2.3 Generowanie propozycji draftu
Stan: `DraftSessionNotifier`
- pobiera zawodnikow skladu,
- wybiera algorytm (`combinatory` lub `greedy`) zaleznie od liczby zawodnikow,
- generuje do 20 propozycji (limit domyslny repozytorium),
- pobiera macierz win-rate par graczy przez RPC `get_player_pair_win_rates`,
- wylicza `homeWinProbability` jako srednia wartosci head-to-head home vs away.

### 2.4 Odczyt zapisanego draftu dla meczu
Scenariusz `matchId` bez `selectedPlayerIds`:
- `GetMatchDraftUseCase` pobiera zapis z `drafts` + `draft_payloads`,
- jesli payload istnieje i status to `completed`, propozycje sa odtwarzane do `Draft`,
- jesli payload nie istnieje, stan jest regenerowany z `ranking_history`/druzyn meczu,
- jesli status to `error`, UI dostaje blad walidacyjny.

### 2.5 Ekran wynikow draftu i finalizacja
Ekran: `DraftResultsPage`
- pokazuje nawigator propozycji (`Draft i of N`),
- pokazuje ranking home/away po korekcie `effectiveTeamRanking`,
- wspiera drag & drop zawodnikow miedzy panelami home/away,
- zapisuje wynik jako `Create Match` (nowy mecz) lub `Update Match` (istniejacy mecz),
- po zapisie przechodzi do `MatchDetailsPage`.

## 3. Routing
Definicje tras sa w `app/lib/core/app_router.dart`:
- `/squads/:squadId/matches/draft` -> `DraftSelectionPage` (`AppRoute.draftSelection`)
- `/squads/:squadId/matches/create` -> `DraftSelectionPage` (`AppRoute.draftCreate`)
- `/squads/:squadId/matches/:matchId/draft` -> `DraftResultsPage` (`AppRoute.matchDraft`)

Nawigacja do feature:
- `SquadMatchesPage` (FAB `+`) prowadzi do `AppRoute.draftCreate`,
- `MatchDetailsPage`:
  - `Wylosuj jeszcze raz` -> `AppRoute.draftCreate` z `selectedIds` i `matchId`,
  - `Wybierz druzyny` -> `AppRoute.draftCreate`,
  - `Podglad propozycji` -> `AppRoute.matchDraft`.

## 4. DB i RLS (zbiorczo)

### 4.1 Tabele
Migracja: `supabase/migrations/20260219110000_create_drafts_tables.sql`

`drafts`:
- `draft_id` (PK, `gen_random_uuid()`),
- `squad_id` (FK -> `squads`, `on delete cascade`),
- `match_id` (FK -> `matches`, `on delete cascade`, `unique`),
- `status` (`completed`/`error`),
- `team_count` (`2..4`),
- `proposals_count` (`>= 0`),
- `error_message`, `created_at`, `updated_at`.

Indeksy:
- `drafts_squad_idx (squad_id)`,
- `drafts_created_at_idx (created_at desc)`.

`draft_payloads`:
- `draft_id` (PK + FK 1:1 -> `drafts.draft_id`, `on delete cascade`),
- `proposals` (`jsonb`, musi byc tablica),
- `win_rate_matrix` (`jsonb`, musi byc obiekt),
- `created_at`, `updated_at`.

### 4.2 RLS
`drafts`:
- `Members can read drafts`: odczyt dla publicznego skladu lub czlonka (`owner/admin/member`),
- `Admins can insert/update/delete drafts`: zapis tylko `owner/admin`.

`draft_payloads`:
- `Members can read draft payloads`: odczyt po relacji do `drafts` + `squads`,
- `Admins can insert/update/delete draft payloads`: zapis tylko `owner/admin`.

### 4.3 RPC/Funkcje SQL uzywane przez feature
- `public.get_player_pair_win_rates(p_player_ids uuid[])`
  - migracja: `supabase/migrations/20251202123000_add_player_pair_win_rates_function.sql`,
  - zwraca pary `(player_id, opp_player_id, win_rate)`,
  - fallback `0.5` gdy brak historii.

### 4.4 Testy SQL
- `supabase/tests/drafts_table_test.sql`
- `supabase/tests/draft_payloads_table_test.sql`

To sa testy smoke (istnienie tabel/constraintow), bez pelnej walidacji polityk RLS.

## 5. Architektura

### 5.1 Domain
Encje:
- `draft.dart` (`Draft`, `DraftTeam`, helpery `homePlayers`/`awayPlayers`),
- `draft_rule.dart` (`DraftRuleType.together`, `DraftRuleType.against`),
- `normalized_draft_rule.dart`,
- `draft_proposal.dart` (wynik scoringu i tie-break),
- `head_to_head_win_rate.dart`,
- `stored_draft_payload.dart`.

Repozytoria:
- `DraftRepository`,
- `DraftPersistenceRepository`,
- `DraftStatsRepository`.

### 5.2 Application
Use case:
- `CreateDraftUseCase` (walidacja max graczy + delegacja do repozytorium),
- `GetPlayerPairWinRatesUseCase`,
- `SaveMatchDraftUseCase`,
- `GetMatchDraftUseCase`.

Providery:
- osobne providery dla repo `combinatory` i `greedy`,
- `createDraftUseCaseProvider`, `combinatoryCreateDraftUseCaseProvider`,
  `greedyCreateDraftUseCaseProvider`.

### 5.3 Infrastructure
`CombinatoryDraftRepository`:
- przeglad wszystkich partycji zespolow przez maski bitowe + Gosper,
- wsparcie `teamCount` od 2 do 4,
- scoring = odchylenie + kara za pozycje + kara za reguly,
- deterministyczne sortowanie (score, tieBreaker, signature).

`GreedyDraftRepository`:
- iteracyjny heurystyczny przydzial graczy (ratio `ranking / weight`),
- dynamiczny budzet iteracji, seed i deduplikacja sygnatur,
- wsparcie `teamCount` od 2 do 4 i regul `together/against`.

`SupabaseDraftPersistenceRepository`:
- upsert do `drafts` (`onConflict: match_id`) i `draft_payloads` (`onConflict: draft_id`),
- serializacja propozycji jako `teams -> [player_id]`,
- metadane seeda w pierwszym elemencie `proposals` pod kluczem `_meta.seed`.

`SupabaseDraftStatsRepository`:
- wywolanie RPC `get_player_pair_win_rates`.

### 5.4 Presentation
Stan:
- `DraftSelectionController` + `DraftSelectionState`,
- `DraftSessionNotifier` + `DraftSessionState`.

Widoki:
- `draft_selection_page.dart`,
- `draft_results_page.dart`,
- `draft_draggable_player_tile.dart`.

UI operuje na modelu home/away (`DraftSessionState.home`, `away`), mimo ze `Draft` wspiera wiele druzyn.

## 6. Integracje / punkty styku
- `players`:
  - `GetSquadPlayersUseCase`,
  - `rankingRepositoryProvider.getMatchRankingHistory` (fallback odtwarzania draftu).
- `matches`:
  - `CreateMatchController.createMatch` i `updateMatch`,
  - `GetMatchUseCase` (fallback do graczy meczu),
  - `matchDetailsProvider` i `squadMatchesProvider` invalidowane po zapisie.
  - Punkty styku po stronie consumer: [matches.md](./matches.md).
- `core`:
  - `effectiveTeamRanking` do obliczen rankingowych i UI,
  - `AppConfig` (`maxPlayersPerMatch`, `greedyDraftThresholdPlayers`, `greedyDraftVariantChecks`).
- `supabase`:
  - tabele `drafts`, `draft_payloads`,
  - RPC `get_player_pair_win_rates`.

## 7. Szybka mapa plikow
- root feature: `app/lib/features/draft/`
- domain:
  - `app/lib/features/draft/domain/entities/*.dart`
  - `app/lib/features/draft/domain/repositories/*.dart`
- application:
  - `app/lib/features/draft/application/create_draft_use_case.dart`
  - `app/lib/features/draft/application/get_match_draft_use_case.dart`
  - `app/lib/features/draft/application/save_match_draft_use_case.dart`
  - `app/lib/features/draft/application/get_player_pair_win_rates_use_case.dart`
- infrastructure:
  - `app/lib/features/draft/infrastructure/repositories/combinatory_draft_repository.dart`
  - `app/lib/features/draft/infrastructure/repositories/greedy_draft_repository.dart`
  - `app/lib/features/draft/infrastructure/repositories/supabase_draft_persistence_repository.dart`
  - `app/lib/features/draft/infrastructure/repositories/supabase_draft_stats_repository.dart`
- presentation:
  - `app/lib/features/draft/presentation/pages/draft_selection_page.dart`
  - `app/lib/features/draft/presentation/pages/draft_results_page.dart`
  - `app/lib/features/draft/presentation/controllers/draft_session_notifier.dart`
  - `app/lib/features/draft/presentation/controllers/draft_selection_controller.dart`
- pliki poza feature:
  - `app/lib/core/app_router.dart`
  - `app/lib/features/matches/presentation/pages/squad_matches_page.dart`
  - `app/lib/features/matches/presentation/pages/match_details_page.dart`
  - `supabase/migrations/20260219110000_create_drafts_tables.sql`
  - `supabase/migrations/20251202123000_add_player_pair_win_rates_function.sql`
  - `supabase/tests/drafts_table_test.sql`
  - `supabase/tests/draft_payloads_table_test.sql`

## 8. Ograniczenia i status
- Aktualny flow UI jest dwudruzynowy (home/away), mimo ze repozytoria draftu obsluguja `teamCount` do 4.
- UI nie wystawia konfiguracji `teamCount` ani regul `DraftRule` (`together`/`against`), chociaz modele i algorytmy to wspieraja.
- `DraftSelectionController.validateSelection()` obecnie tylko czysci komunikat; brak dodatkowych walidacji biznesowych.
- `AppRoute.draftCreate` i `AppRoute.draftSelection` prowadza do tego samego ekranu (`DraftSelectionPage`).
- Draft pages nie maja wlasnego route-guardu roli; kontrola dostepu opiera sie glownie o miejsca wejscia w feature (`matches` UI) oraz RLS po stronie DB.
