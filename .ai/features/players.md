## Plan implementacji feature'u Players

### 1. Cel feature'u
- **Opis biznesowy**: Zarządzanie zawodnikami (`players`) w obrębie konkretnego składu (`squad`): lista, filtrowanie/sortowanie oraz CRUD dla uprawnionych ról (Admin/Owner).
- **Powiązane wymagania**:
  - **UI**: `PlayersPage` pod ścieżką `/squads/:squadId/players`, lista graczy z filtrem/sortem, pozycja, `score`, `base_score`, licznik graczy, komponenty: `PlayersListWidget`, `SearchBar`, `SortMenu`, `CreatePlayerDialog`.
  - **PRD**: US-005 – CRUD graczy w składzie, ograniczenie do ról Admin/Owner, walidacja duplikatów nazw w obrębie składu (best effort).
  - **DB**: Tabela `players` (`player_id`, `squad_id`, `name`, `position`, `base_score`, `score`, `created_at`, `updated_at`, `is_deleted`).

### 2. Struktura katalogów feature'u `players`
Wszystko w `app/lib/features/players`:

- **domain/**
  - **entities/**
    - `player.dart` – encja domenowa gracza.
  - **repositories/**
    - `player_repository.dart` – interfejs repozytorium graczy.

- **application/**
  - **usecases/**
    - `get_squad_players_usecase.dart`
    - `get_player_details_usecase.dart` (**TODO** – pusta implementacja logiki).
    - `add_player_usecase.dart`
    - `update_player_usecase.dart`
    - `delete_player_usecase.dart`

- **infrastructure/**
  - **models/**
    - `player_model.dart` – DTO ↔ Supabase (`players` table), `@JsonSerializable(fieldRename: FieldRename.snake)`.
  - **datasources/**
    - `players_remote_data_source.dart` – niskopoziomowe wywołania Supabase.
  - **repositories/**
    - `player_repository_impl.dart` – implementacja `PlayerRepository` oparta na `PlayersRemoteDataSource`.

- **presentation/**
  - **pages/**
    - `players_page.dart` – główny widok PlayersPage (ścieżka `/squads/:squadId/players`).
  - **controllers/**
    - `players_notifier.dart` – `@riverpod` notifier z `AsyncValue` dla listy graczy.
    - (opcjonalnie na później) `player_details_notifier.dart` – pod szczegóły gracza.
  - **widgets/**
    - `players_list_widget.dart` – lista/karty/tabela graczy.
    - `players_search_bar.dart` – wyszukiwanie po nazwie.
    - `players_sort_menu.dart` – sortowanie po pozycji / score / nazwie.
    - `create_player_dialog.dart` – dialog do tworzenia gracza.
    - `empty_players_state.dart` – widok pustej listy.
    - `players_error_view.dart` – wrapper na błędy (`SelectableText.rich`).

### 3. Model domenowy i repozytorium
- **Encja `Player` (`domain/entities/player.dart`)**:
  - Pola: `id` (UUID), `squadId` (UUID), `name` (String), `position` (String?), `baseScore` (int), `score` (double), `createdAt`, `updatedAt`, `isDeleted`.
  - Immutable, `const` konstruktor, bez zależności od warstw niższych.

- **Interfejs repozytorium (`domain/repositories/player_repository.dart`)**:
  - `Future<List<Player>> getSquadPlayers({required String squadId});`
  - `Future<Player> getPlayer({required String playerId});`
  - `Future<Player> addPlayer({required String squadId, required String name, String? position, int baseScore});`
  - `Future<void> deletePlayer({required String playerId});`
  - `Future<Player> updatePlayer({required String playerId, String? name, int? baseScore, double? score});`
  - Zwracanie błędów poprzez `Failure` (z `core/error/failure.dart`); w warstwie presentation notifiery będą używać `AsyncValue.guard` do opakowywania operacji asynchronicznych.

### 4. Warstwa infrastructure (Supabase)
- **Supabase `SupabasePlayerRepository` (`infrastructure/repositories/supabase_player_repository.dart`)**:
  - Bezpośrednia integracja z `SupabaseClient` z `core/global_dependencies.dart`.
  - Operuje wyłącznie na encji domenowej `Player` – pomijamy osobne DTO / modele.
  - Odpowiada za:
    - Wywołania na tabeli `players` (`insert` / `select` / `update` / `delete`) z użyciem `from`, `eq` itd.
    - Mapowanie `Map<String, dynamic>` ↔ `Player` bezpośrednio wewnątrz repozytorium.
    - Obsługę i mapowanie błędów Supabase na `Failure` (w tym konflikt nazwy w obrębie `squad_id` na `Failure.duplicateName`).
    - Respektowanie RLS (Admin/Owner) – błędy 401/403/itp. konwertowane na odpowiednie typy `Failure`.

### 5. Warstwa application – use case'y
- **`GetSquadPlayersUseCase`**:
  - Wejście: `squadId`.
  - Wyjście: `List<Player>`.
  - Używany przez `PlayersNotifier` przy init/refresh.

- **`GetPlayerDetailsUseCase`**:
  - Definicja klasy, wstrzyknięcie `PlayerRepository`, sygnatura metody `call`, ale **bez implementacji** (TODO – zaimplementujemy przy tworzeniu PlayersDetailsPage).

- **`AddPlayerUseCase`**:
  - Wejście: `squadId`, `name`, `position?`, `baseScore`.
  - Walidacje po stronie use case:
    - Proste sprawdzenia (np. `name.isNotEmpty`), reszta na backendzie (constraint/409).
  - Po sukcesie: zwrócenie nowego `Player` (lub tylko `void` + odświeżenie listy w notifierze).

- **`UpdatePlayerUseCase`**:
  - Wejście: `playerId`, opcjonalnie `name`, `baseScore`, `score`.
  - Implementacja w pełni, ale **nie używana jeszcze na `PlayersPage`**, tylko przygotowana pod przyszły `PlayerDetailsPage`.

- **`DeletePlayerUseCase`**:
  - Wejście: `playerId`.
  - Po sukcesie: notifier odświeża listę (`ref.invalidate` lub lokalny update stanu).

### 6. Warstwa presentation – stan i notifiery
- **`PlayersNotifier` (`presentation/controllers/players_notifier.dart`)**:
  - `@riverpod` / `AsyncNotifier<List<Player>>`.
  - Zależności: `GetSquadPlayersUseCase`, `AddPlayerUseCase`, `DeletePlayerUseCase`.
  - API:
    - `Future<void> loadPlayers(String squadId);`
    - `Future<void> refreshPlayers();`
    - `Future<void> addPlayer({...});`
    - `Future<void> deletePlayer(String playerId);`
  - Stan dodatkowy:
    - Filtry/sortowanie (np. `searchQuery`, `sortOption`) – osobny notifier lub dodatkowe pola w stanie (np. dedykowana klasa `PlayersState` zamiast samego `List<Player>`).
  - Obsługa:
    - `AsyncValue.loading` / `AsyncValue.data` / `AsyncValue.error`.
    - Błędy renderowane na UI przez `SelectableText.rich` w `PlayersErrorView`.

- **(na później) `PlayerDetailsNotifier`**:
  - `AsyncNotifier<Player>`, wykorzysta `GetPlayerDetailsUseCase` i `UpdatePlayerUseCase`.

### 7. Warstwa presentation – UI (`PlayersPage` i widżety)
- **Routing**:
  - Dodanie wpisu do konfiguracji routera (np. GoRouter) z path: `/squads/:squadId/players`.
  - Ekstrakcja `squadId` z parametrów trasy, przekazanie do `PlayersNotifier`.

- **`PlayersPage` (`presentation/pages/players_page.dart`)**:
  - Layout:
    - AppBar / nagłówek z nazwą składu i liczbą graczy.
    - Pasek wyszukiwarki (`PlayersSearchBar`).
    - Menu sortowania (`PlayersSortMenu`).
    - Przycisk **Add Player** (widoczny tylko dla ról Admin/Owner – bazując na globalnym stanie auth/role).
    - Główna lista (`PlayersListWidget`) z `RefreshIndicator`.
  - Renderowanie `AsyncValue`:
    - `loading`: wskaźnik ładowania (np. `CircularProgressIndicator` lub skeleton listy).
    - `error`: `PlayersErrorView` z `SelectableText.rich` w kolorze czerwonym.
    - `data`: lista lub `EmptyPlayersState` (gdy brak graczy).

- **Dialog dodawania gracza (`CreatePlayerDialog`)**:
  - Formularz:
    - `TextField` dla `name` (walidacja: niepusty).
    - `TextField` dla `position` (opcjonalny).
    - `TextField` / `TextFormField` dla `baseScore` (tylko liczby całkowite).
  - Po submit:
    - Wywołanie `PlayersNotifier.addPlayer`.
    - Obsługa błędów, w tym duplikatu nazwy (komunikat w UI na podstawie `Failure.duplicateName`).

- **Lista graczy (`PlayersListWidget`)**:
  - `ListView.builder` / responsywne karty lub tabela (w zależności od szerokości ekranu).
  - Element listy:
    - Nazwa, pozycja, `baseScore`, `score`.
    - Akcje:
      - `Delete` (tylko Admin/Owner) – potwierdzenie przed wywołaniem `deletePlayer`.
      - (na później) `Details` – nawigacja do `PlayerDetailsPage`.

### 8. Flow danych (end-to-end)
- **Kierunek przepływu**:
  - `PlayersPage` (UI) → `PlayersNotifier` (presentation/controller) → Use case'y (application) → `PlayerRepository` (domain) → `PlayerRepositoryImpl` + `PlayersRemoteDataSource` (infrastructure) → Supabase.
  - Odpowiedzi z Supabase → `PlayersRemoteDataSource` → `PlayerRepositoryImpl` → encje `Player` → Use case'y → `PlayersNotifier` (`AsyncValue`) → `PlayersPage` / widżety.

- **Typowe scenariusze**:
  - **Wejście na `/squads/:squadId/players`**:
    - Router tworzy `PlayersPage`, ta odczytuje `squadId`.
    - `PlayersNotifier.loadPlayers(squadId)` wywołuje `GetSquadPlayersUseCase`.
  - **Dodanie gracza**:
    - Użytkownik (Admin/Owner) otwiera `CreatePlayerDialog`.
    - Po submit: `PlayersNotifier.addPlayer` → `AddPlayerUseCase` → repo/infra → po sukcesie odświeżenie listy (`loadPlayers` lub lokalny update).
  - **Usunięcie gracza**:
    - Z elementu listy wywołanie `deletePlayer` → `DeletePlayerUseCase` → repo/infra → po sukcesie aktualizacja stanu listy.

### 9. Techniczne kroki implementacji (kolejność)
- **Krok 1 – Domain**:
  - Stworzenie `Player` entity oraz `PlayerRepository` interface.

- **Krok 2 – Infrastructure**:
  - Implementacja `PlayerModel`, `PlayersRemoteDataSource` i `PlayerRepositoryImpl`.
  - Dodanie integracji z `SupabaseClient` i mapowań błędów na `Failure`.

- **Krok 3 – Application**:
  - Implementacja use case'ów:
    - `GetSquadPlayersUseCase`, `AddPlayerUseCase`, `DeletePlayerUseCase`, `UpdatePlayerUseCase`.
    - `GetPlayerDetailsUseCase` jako szkielet (bez realnej logiki, tylko TODO).

- **Krok 4 – Presentation (stan)**:
  - Implementacja `PlayersNotifier` z `AsyncValue`.
  - Ewentualny prosty stan na filtry/sortowanie (lub TODO, jeśli nie zdążymy).

- **Krok 5 – Presentation (UI)**:
  - `PlayersPage` + routing.
  - Widżety: `PlayersListWidget`, `PlayersSearchBar`, `PlayersSortMenu`, `CreatePlayerDialog`, `EmptyPlayersState`, `PlayersErrorView`.
  - Odtworzenie UX z legacy `players_page.dart`, ale zgodnie z nowym designem (responsywne karty/tabela, SelectableText dla błędów).

- **Krok 6 – Integracja i testy**:
  - Podpięcie feature'u do globalnej nawigacji (panel Players z widoku squadu).
  - Testy:
    - Unit testy use case'ów (happy/failure path).
    - Testy repozytorium z mockowanym `SupabaseClient`.
    - Testy notifiera (zmiany `AsyncValue`).

### 10. Rzeczy oznaczone jako TODO / później
- Implementacja faktycznej logiki w `GetPlayerDetailsUseCase` i budowa `PlayerDetailsPage`.
- Zaawansowane filtrowanie/sortowanie (po wielu polach, wielokryterialne).
- Paginations / infinite scroll (jeśli zajdzie potrzeba).
- Dopracowanie roli i uprawnień na poziomie UI (np. ukrywanie akcji w zależności od roli).


