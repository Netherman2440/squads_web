# ranking_history - dokumentacja feature (stan aktualny)

Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `ranking_history` odpowiada za rejestrowanie zmian rankingu zawodnikow oraz odtwarzanie ich w UI i logice meczow.

Zakres implementacji obejmuje:
- zapisy historii rankingu powiazane z meczami i recznymi korektami,
- aktualizacje `players.score` na podstawie zmian delty,
- odczyt historii na ekranie szczegolow zawodnika,
- integracje z flow meczowym (`create/update/delete match`, edycja skladow) i draftem.

Technicznie logika jest ulokowana glownie w `app/lib/features/players`, ale jest wywolywana takze z `features/matches` i `features/draft`.

Ten dokument jest source of truth dla aktualizacji rankingu i lifecycle wpisow `ranking_history`. Inne feature opisuja ten obszar tylko jako punkty styku.

## 2. Co jest zaimplementowane

### 2.1 Tworzenie wpisow historii dla meczu
- `CreateMatchUseCase` tworzy wpis `ranking_history` dla kazdego zawodnika meczu przez `createMatchRankingEntry`.
- Wpis startowy ma:
  - `ranking` = biezacy ranking gracza,
  - `change` = `null`,
  - `match_id` = ID meczu.
- `UpdateMatchTeamsUseCase` (tylko gdy mecz nie ma wyniku) dopina wpisy dla nowo dodanych graczy i usuwa wpisy dla usunietych graczy.

### 2.2 Aktualizacja rankingu po wpisaniu wyniku meczu
- `UpdateMatchScoreUseCase` aktualizuje wynik meczu i, gdy `squad.rankingUpdate == true`, wylicza delty:
  - `delta = (homeScore - awayScore) * rankingMultiplier`,
  - gracze home dostaja `+delta`, away `-delta`.
- Jesli `useExperienceFactor == true`, delta dzielona jest przez liczbe wpisow meczowych gracza (`ranking_history` z `match_id != null`, clamp `1..10`).
- Dla kazdego gracza:
  - pobierany jest wpis historii `(player_id, match_id)`,
  - liczona jest roznica wzgledem poprzedniej delty,
  - docelowy ranking jest clampowany do `0..100`,
  - aktualizowane sa `ranking_history.change`, `ranking_history.updated_at` oraz `players.score`.

### 2.3 Reczna korekta rankingu
- Z `PlayerDetailsPage` (dialog `EditPlayerRankingDialog`) mozna recznie ustawic ranking.
- `UpdatePlayerRankingUseCase` wywoluje `RankingRepository.updatePlayerRanking(..., matchId: null)`.
- Repozytorium:
  - pobiera biezace `players.score`,
  - zapisuje manualny wpis historii (`match_id = null`, `ranking = oldScore`, `change = new-old`),
  - aktualizuje `players.score`.

### 2.4 Odczyt i wizualizacja historii
- `GetPlayerRankingHistoryUseCase` zwraca historie gracza malejaco po `created_at`.
- `playerDetailsProvider` laduje rownolegle dane gracza i historie.
- `RankingHistoryGraphWidget`:
  - sortuje historie rosnaco po `created_at`,
  - zaczyna wykres od `baseRanking`,
  - buduje przebieg przez kumulacje `change` (dla `null` traktuje `0`).
- `GetPlayerMatchesUseCase` wykorzystuje `ranking_history.match_id` do pobrania listy meczow zawodnika.

### 2.5 Usuwanie i rollback
- `DeleteMatchUseCase` usuwa wpisy rankingowe meczu dla wszystkich jego zawodnikow.
- `deleteMatchRankingEntry`:
  - odejmuje stara delte od `players.score` (jesli `change != null`),
  - usuwa wpis z `ranking_history`.
- Usuniecie zawodnika usuwa jego historie automatycznie przez FK `ranking_history.player_id -> players.player_id ON DELETE CASCADE`.

## 3. Routing
- Feature nie ma osobnej trasy typu `/ranking-history`.
- Historia rankingu jest dostepna w:
  - `/squads/:squadId/players/:playerId` (`PlayerDetailsPage`).
- Wejscia do widoku szczegolow zawodnika:
  - lista graczy (`PlayersListWidget`),
  - widok szczegolow meczu (`MatchDetailsPage`, klik na zawodnika).
- Powiazana podstrona oparta o historie:
  - `/squads/:squadId/players/:playerId/matches` (lista meczow wyliczana przez `ranking_history.match_id`).

## 4. DB i RLS (zbiorczo)

### 4.1 Tabela `ranking_history`
Migracja: `supabase/migrations/20251201090900_create_ranking_history_table.sql`

Kluczowe pola:
- `ranking_history_id` UUID PK,
- `player_id` UUID FK -> `players(player_id)` `ON DELETE CASCADE`,
- `match_id` UUID NULL FK -> `matches(match_id)` `ON DELETE SET NULL`,
- `ranking` numeric(6,3) (snapshot rankingu przed zmiana),
- `change` numeric(6,3) NULL (delta),
- `match_score` JSONB NULL,
- `created_at`, `updated_at`.

Kluczowe indeksy/ograniczenia:
- unique partial index `(player_id, match_id)` gdzie `match_id is not null`,
- indeks po `player_id`,
- indeks po `match_id` (partial).

### 4.2 RLS dla `ranking_history`
- `SELECT`: czlonkowie skladu lub kazdy dla skladu publicznego.
- `INSERT/UPDATE/DELETE`: tylko `owner/admin`.
- Dla operacji zapisu dodatkowo sprawdzana jest spojnosc `player_id` z `match_id` (zawodnik nalezy do skladu meczu).

### 4.3 Powiazane kontrakty DB
- `players.score` ma check `0..100` (migracja `20251201090400_create_players_table.sql`) i jest aktualizowane razem z historia.
- `squads` trzyma ustawienia wplywajace na delty:
  - `ranking_update`,
  - `ranking_multiplier` (`1..10`),
  - `use_experience_factor`
  (migracja `20251201090200_create_squads_table.sql`).

### 4.4 RPC/Funkcje SQL
- W aktualnej implementacji ranking history nie korzysta z dedykowanej funkcji RPC do atomowego przeliczania.
- Aktualizacje sa wykonywane przez sekwencje operacji z poziomu repozytoriow.

## 5. Architektura

### 5.1 Domain
- Encja: `RankingHistoryEntry`.
- Repozytorium: `RankingRepository`.
- Wyjatki domenowe:
  - `RankingHistoryNotFoundException`,
  - `RankingUpdateConflictException`.

### 5.2 Application
- Odczyt historii:
  - `GetPlayerRankingHistoryUseCase`.
- Reczna korekta:
  - `UpdatePlayerRankingUseCase`.
- Integracje z meczami:
  - `CreateMatchUseCase` (zakladanie wpisow),
  - `UpdateMatchScoreUseCase` (aktualizacja delty i score),
  - `UpdateMatchTeamsUseCase` (dodawanie/usuwanie wpisow przy zmianie skladow bez wyniku),
  - `DeleteMatchUseCase` (rollback + usuniecie wpisow).
- Integracja posrednia:
  - `GetPlayerMatchesUseCase` (match IDs z historii).

### 5.3 Infrastructure
- `SupabaseRankingRepository`:
  - odczyt historii dla gracza i meczu,
  - aktualizacje manualne i meczowe,
  - tworzenie/usuwanie wpisow meczowych,
  - aktualizacja `change` przez `updateMatchRankingChange`.
- `SupabasePlayerRepository`:
  - zapis finalnego `players.score` (`updatePlayerRanking`).
- `SupabaseTeamRepository`:
  - podczas odczytu zespolow meczu laczy dane z `ranking_history`, aby pokazac ranking zwiazany z danym meczem.

### 5.4 Presentation
- `PlayerDetailsPage` + `playerDetailsProvider` pobieraja i renderuja historie.
- `RankingHistoryGraphWidget` pokazuje przebieg zmian.
- `EditPlayerRankingDialog` uruchamia manualna korekte.
- `MatchDetailsNotifier.updateScore` po aktualizacji wyniku invaliduje `playerDetailsProvider` dla graczy meczu, aby odswiezyc historie i ranking.

## 6. Integracje / punkty styku
- `matches`:
  - tworzy wpisy historii przy tworzeniu meczu,
  - aktualizuje delty i rankingi po wpisaniu/edycji wyniku,
  - zarzadza wpisami historii przy edycji skladow (gdy brak wyniku),
  - usuwa wpisy historii przy usuwaniu meczu.
  - Punkty styku po stronie consumer: [matches.md](./matches.md).
- `squads`:
  - ustawienia rankingu skladu steruja tym, czy i jak wynik meczu zmienia ranking.
  - Punkty styku po stronie consumer: [squads.md](./squads.md).
- `draft`:
  - `DraftSessionNotifier` i `DraftResultsPage` odczytuja `getMatchRankingHistory(matchId)` do odtworzenia listy zawodnikow dla draftu meczu.
  - Punkty styku po stronie consumer: [draft.md](./draft.md).
- `players`:
  - widok szczegolow i podstrona meczow zawodnika opieraja sie o `ranking_history`.
  - Punkty styku po stronie consumer: [players.md](./players.md).
- `stats`:
  - statystyki sa pochodna danych rankingowych i wynikow meczow.
  - Definicja metryk stats jest utrzymywana w [stats.md](./stats.md).

## 7. Szybka mapa plikow
- `app/lib/features/players/domain/entities/ranking_history_entry.dart`
- `app/lib/features/players/domain/repositories/ranking_repository.dart`
- `app/lib/features/players/domain/exceptions/ranking_exceptions.dart`
- `app/lib/features/players/infrastructure/repositories/supabase_ranking_repository.dart`
- `app/lib/features/players/application/usecases/get_player_ranking_history_usecase.dart`
- `app/lib/features/players/application/usecases/update_player_ranking_usecase.dart`
- `app/lib/features/players/application/usecases/get_player_matches_usecase.dart`
- `app/lib/features/players/presentation/controllers/player_details_controller.dart`
- `app/lib/features/players/presentation/pages/player_details_page.dart`
- `app/lib/features/players/presentation/widgets/ranking_history_graph_widget.dart`
- `app/lib/features/players/presentation/widgets/edit_player_ranking_dialog.dart`
- `app/lib/features/matches/application/usecases/create_match_usecase.dart`
- `app/lib/features/matches/application/usecases/update_match_score_usecase.dart`
- `app/lib/features/matches/application/usecases/update_match_teams_usecase.dart`
- `app/lib/features/matches/application/usecases/delete_match_usecase.dart`
- `app/lib/features/draft/presentation/controllers/draft_session_notifier.dart`
- `supabase/migrations/20251201090900_create_ranking_history_table.sql`
- `supabase/migrations/20251201090400_create_players_table.sql`
- `supabase/migrations/20251201090200_create_squads_table.sql`

## 8. Ograniczenia i status (opcjonalnie, ale zalecane)
- Brak osobnego ekranu/zakladki dedykowanej tylko historii rankingu; historia jest czescia `PlayerDetailsPage`.
- Brak atomowej transakcji DB/RPC dla operacji typu "update wpisu historii + update players.score"; operacje sa wykonywane sekwencyjnie.
- Brak pelnego recompute calej historii gracza po zmianie starego wyniku; obecny flow stosuje roznice delty (`newDelta - oldDelta`) do biezacego rankingu.
- Kolumna `ranking_history.match_score` istnieje w DB i encji, ale aktualny kod jej nie zapisuje.
- Wykres historii opiera sie na `baseRanking + suma(change)`; nie renderuje osi czasu i nie wykorzystuje bezposrednio pola `ranking` jako punktow wykresu.
- Brak dedykowanych testow SQL i testow Flutter skoncentrowanych wylacznie na `ranking_history`.
