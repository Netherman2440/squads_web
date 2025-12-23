## Plan implementacji feature'u Player Details

### 1. Cel i zakres
- **Cel**: Dostarczyć widok szczegolow gracza pod URL `/squads/:squadId/players/:playerId`, z podstawowymi informacjami, statystykami i szybka nawigacja (zgodnie z US-009).
- **Zakres MVP**:
  - ekran moze byc poczatkowo zmockowany (placeholder UI), ale z poprawnym routowaniem;
  - minimalny zakres danych: imie, pozycja, base_score, score.
- **Zakres docelowy**:
  - statystyki (W/L, liczba meczow, srednia delta score),
  - historia zmian rankingu (score history),
  - lista ostatnich meczow gracza (z linkami do match details),
  - akcje admin/owner (edycja, usuniecie).

### 2. Wejscia z PRD
- **US-009**: szybka nawigacja do szczegolow gracza.
  - Klikniecie gracza na liscie przenosi na `/squads/:squadId/players/:playerId`.
  - Widok na razie moze byc zmockowany.

### 3. UX/UI (propozycja ukladu)
- **Naglowek**: imie gracza, tag pozycji, aktualny score.
- **Sekcja statystyk** (kafelki): mecze, W/L, win rate, srednia delta.
- **Wykres score history**: prosty wykres liniowy z `score_history` (opcjonalnie w MVP jako placeholder).
- **Ostatnie mecze**: lista z wynikiem i data; klikniecie prowadzi do match details.
- **Akcje** (widoczne tylko dla admin/owner): Edytuj gracza, Usun gracza.
- **Stany**:
  - loading: skeleton/spinner,
  - error: komunikat z mozliwoscia ponowienia,
  - empty: brak historii meczow.

### 4. Struktura feature'u (Clean Architecture)
W `app/lib/features/players/` z osobnym podfolderem dla szczegolow:

- **domain/**
  - `entities/player.dart` (juz istnieje)
  - `entities/score_history_entry.dart` (z `score_history.md`)
  - `repositories/player_repository.dart` (rozszerzenie kontraktu)

- **application/**
  - `usecases/get_player_details_usecase.dart` (pelna implementacja)
  - `usecases/get_player_score_history_usecase.dart` (pod wykres)
  - `usecases/get_player_recent_matches_usecase.dart` (opcjonalnie, zalezne od Matches)
  - `usecases/get_player_stats_usecase.dart` (agregaty W/L)

- **infrastructure/**
  - `datasources/players_remote_data_source.dart` (rozszerzenie o detale i staty)
  - `repositories/player_repository_impl.dart` (mapowania)

- **presentation/**
  - `pages/player_details_page.dart`
  - `controllers/player_details_notifier.dart`
  - `widgets/`:
    - `player_header.dart`
    - `player_stats_grid.dart`
    - `player_score_chart.dart`
    - `player_recent_matches.dart`
    - `player_details_error_view.dart`

### 5. Kontrakty danych i zapytania
- **Players**: `players` (id, squad_id, name, position, base_score, score).
- **Score history**: `score_history` (player_id, match_id, delta, previous_rating, new_rating, created_at).
- **Matches**: join przez `match_players` (jesli istnieje w DB) lub relacje w `matches`/`teams`.

Propozycja zapytan:
- `getPlayer(playerId)` -> podstawowe dane.
- `getPlayerScoreHistory(playerId)` -> lista wpisow do wykresu.
- `getPlayerRecentMatches(playerId, limit)` -> ostatnie mecze + wynik.
- `getPlayerStats(playerId)` -> agregaty (W/L, total matches, avg delta).

### 6. RBAC
- **Read**: public squads dla guest, private tylko dla members.
- **Write**: edit/delete tylko Owner/Admin (zgodnie z players feature).
- RBAC sprawdzamy w UI na podstawie roli w `SquadShell`/`auth` state.

### 7. Routing i nawigacja
- Dodac route w GoRouter:
  - `/squads/:squadId/players/:playerId` -> `PlayerDetailsPage`.
- Z `PlayersListWidget` dodac `onTap` do nawigacji.

### 8. Notifier i stan
- `PlayerDetailsNotifier` jako `AsyncNotifier<PlayerDetailsState>`:
  - `Player` + `stats` + `scoreHistory` + `recentMatches`.
  - `build(squadId, playerId)` pobiera dane rownolegle.
  - `refresh()` do ponownego pobrania.

### 9. Testy
- **Unit**:
  - `GetPlayerDetailsUseCase` (happy path, not found).
  - `GetPlayerStatsUseCase` (poprawne agregaty).
- **Notifier**:
  - stan loading -> data/error.
- **Widget**:
  - render header + stats,
  - empty state bez historii.

### 10. Etapy wdrozenia
1) Routing + placeholder `PlayerDetailsPage` (MVP szybkie spiecie US-009).
2) Implementacja `GetPlayerDetailsUseCase` + podstawowe dane.
3) Dodanie statystyk i historii score (wspolnie ze `score_history` logika).
4) Ostatnie mecze + akcje admin (edit/delete).

