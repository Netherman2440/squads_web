# Players - dokumentacja feature (stan aktualny)

Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `players` odpowiada za:
- zarzadzanie lista zawodnikow w skladzie,
- przeglad szczegolow zawodnika,
- historie rankingu zawodnika,
- statystyki zawodnika i head-to-head,
- liste meczow zawodnika.

Zakres obejmuje warstwy `domain`, `application`, `infrastructure` i `presentation` w `app/lib/features/players`.

## 2. Co jest zaimplementowane

### 2.1 Lista zawodnikow
Ekran: `PlayersPage` (`/squads/:squadId/players`)
- pobranie listy graczy dla skladu,
- wyszukiwanie po nazwie,
- sortowanie po rankingu i nazwie,
- pull-to-refresh,
- przejscie do szczegolow zawodnika po kliknieciu na tile.

### 2.2 Dodawanie zawodnika
Dialog: `CreatePlayerDialog`
- pola: `name`, `position` (opcjonalne), `base ranking`,
- slider `1..100` + pole tekstowe z synchronizacja,
- podglad najblizszego slabszego i silniejszego gracza,
- walidacja nazwy i duplikatu po stronie UI oraz constraint po stronie DB.

### 2.3 Szczegoly zawodnika
Ekran: `PlayerDetailsPage` (`/squads/:squadId/players/:playerId`)
- profil zawodnika (nazwa, aktualny ranking, roznica do base),
- wykres historii rankingu (`RankingHistoryGraphWidget`),
- edycja nazwy (admin/owner),
- reczna edycja rankingu (admin/owner),
- usuwanie zawodnika (admin/owner),
- sekcja nawigacyjna do:
  - `Matches`,
  - `Stats`,
  - `Tournaments` (na razie placeholder "Coming soon").

### 2.4 Mecze zawodnika
Ekran: `PlayerMatchesPage` (`/squads/:squadId/players/:playerId/matches`)
- lista meczow wyliczana na podstawie `ranking_history.match_id`,
- render przez wspolny `MatchTile`.

### 2.5 Statystyki zawodnika
Ekran: `PlayerStatsPage` (`/squads/:squadId/players/:playerId/stats`)
- kafelki statystyk agregowanych (`get_player_stats`),
- tabela head-to-head (`get_player_head_to_head_stats`),
- sortowanie kolumn w tabeli.

## 3. Routing
Definicje tras sa w `app/lib/core/app_router.dart`:
- `/squads/:squadId/players` -> `PlayersPage`
- `/squads/:squadId/players/:playerId` -> `PlayerDetailsPage`
- `/squads/:squadId/players/:playerId/matches` -> `PlayerMatchesPage`
- `/squads/:squadId/players/:playerId/stats` -> `PlayerStatsPage`

## 4. Uprawnienia

### 4.1 Widok UI
- przycisk `Add Player` jest widoczny tylko dla `owner/admin`,
- edycja nazwy/rankingu i usuwanie na details tylko dla `owner/admin`.

### 4.2 RLS (Supabase)
- `players`: odczyt dla czlonkow/public, modyfikacja tylko `owner/admin`,
- `ranking_history`: odczyt dla czlonkow/public, modyfikacja tylko `owner/admin`.

Polityki sa w migracjach:
- `supabase/migrations/20251201090400_create_players_table.sql`
- `supabase/migrations/20251201090900_create_ranking_history_table.sql`

## 5. Architektura (kod)

### 5.1 Domain
- encje:
  - `player.dart`
  - `ranking_history_entry.dart`
  - `player_stats.dart`
  - `player_head_to_head_stat.dart`
- repozytoria:
  - `player_repository.dart`
  - `ranking_repository.dart`

### 5.2 Application (use case)
- lista i CRUD:
  - `get_squad_players_usecase.dart`
  - `add_player_usecase.dart`
  - `delete_player_usecase.dart`
  - `get_player_details_usecase.dart`
  - `update_player_name_usecase.dart`
  - `update_player_position_usecase.dart`
  - `update_player_ranking_usecase.dart`
- historia/statystyki:
  - `get_player_ranking_history_usecase.dart`
  - `get_player_matches_usecase.dart`
  - `get_player_stats_usecase.dart`
  - `get_player_head_to_head_stats_usecase.dart`

### 5.3 Infrastructure
- `SupabasePlayerRepository`:
  - CRUD na tabeli `players`,
  - `updatePlayerRanking` przez update `players.score`,
  - RPC: `get_player_stats`, `get_player_head_to_head_stats`.
- `SupabaseRankingRepository`:
  - odczyt historii rankingu,
  - reczna korekta rankingu (manual entry + update `players.score`),
  - operacje na wpisach meczowych (`create/update/delete` wpisow rankingowych).

### 5.4 Presentation
- stan listy: `players_notifier.dart`,
- stan details: `player_details_controller.dart`,
- stan podstron:
  - `player_matches_provider.dart`,
  - `player_stats_provider.dart`,
- widoki i widgety:
  - `players_page.dart`,
  - `player_details_page.dart`,
  - `player_matches_page.dart`,
  - `player_stats_page.dart`,
  - `players_list_widget.dart`,
  - `create_player_dialog.dart`,
  - `edit_player_name_dialog.dart`,
  - `edit_player_ranking_dialog.dart`,
  - `ranking_history_graph_widget.dart`,
  - `player_head_to_head_table.dart`.

## 6. Kontrakty danych (DB/RPC)

### 6.1 `players`
Kluczowe pola:
- `player_id` (PK),
- `squad_id` (FK -> `squads`),
- `name`,
- `position` (nullable),
- `base_score` (`0..100`),
- `score` (`0..100`, numeric).

W kodzie mapowane jako:
- `base_score` -> `Player.baseRanking`,
- `score` -> `Player.ranking`.

### 6.2 `ranking_history`
- Feature `players` korzysta z `ranking_history` do:
  - wykresu historii rankingu,
  - recznych korekt rankingu,
  - wyliczania listy meczow zawodnika.
- Pelny kontrakt DB/RLS i lifecycle wpisow jest utrzymywany w [ranking_history.md](./ranking_history.md).

### 6.3 RPC uzywane przez feature
- `get_player_stats(p_player_id uuid)`
- `get_player_head_to_head_stats(p_player_id uuid)`

Migracje:
- `supabase/migrations/20251202125000_add_player_stats_function.sql`
- `supabase/migrations/20251202120000_add_player_head_to_head_stats_function.sql`

## 7. Integracje / punkty styku
- `matches`:
  - `CreateMatchUseCase`, `UpdateMatchScoreUseCase`, `UpdateMatchTeamsUseCase`, `DeleteMatchUseCase` korzystaja z `PlayerRepository` i `RankingRepository`.
  - Szczegoly flow meczowego sa utrzymywane w [matches.md](./matches.md).
- `ranking_history`:
  - `players` jest glownym konsumentem odczytu historii (`PlayerDetailsPage`, `RankingHistoryGraphWidget`, `PlayerMatchesPage`),
  - ale definicja aktualizacji i rollbacku rankingu jest utrzymywana w [ranking_history.md](./ranking_history.md).
- `stats`:
  - `PlayerStatsPage` i `PlayerHeadToHeadTable` korzystaja z metryk z RPC `get_player_stats` i `get_player_head_to_head_stats`,
  - definicja metryk i kontrakt stats sa utrzymywane w [stats.md](./stats.md).

## 8. Walidacje i obsluga bledow
- `AddPlayerUseCase`:
  - nazwa nie moze byc pusta,
  - `baseRanking` nie moze byc ujemny.
- UI tworzenia gracza:
  - slider ogranicza ranking do `1..100`,
  - lokalny check duplikatu nazwy (best effort).
- DB wymusza unikalnosc `(squad_id, name)` i zakresy score/base_score.
- bledy Supabase mapowane sa przez `supabase_error_extension.dart` na `Failure`.

## 9. Ograniczenia i status
- `Tournaments` na `PlayerDetailsPage` nie jest jeszcze zaimplementowane.
- `UpdatePlayerPositionUseCase` istnieje, ale brak dedykowanego UI do edycji pozycji.
- `GetPlayerDetailsUseCase` zwraca obecnie tylko `Player` (bez dodatkowych agregatow).
- `app/test` nie zawiera aktualnie testow dedykowanych feature `players`.

## 10. Szybka mapa plikow
- root feature: `app/lib/features/players/`
- router: `app/lib/core/app_router.dart`
- migracje SQL:
  - `supabase/migrations/20251201090400_create_players_table.sql`
  - `supabase/migrations/20251201090900_create_ranking_history_table.sql`
  - `supabase/migrations/20251202120000_add_player_head_to_head_stats_function.sql`
  - `supabase/migrations/20251202125000_add_player_stats_function.sql`
