
### Matches — plan implementacji (US-006…US-009 + fundament pod draft/score history)

Ten dokument opisuje **plan wdrożenia featuru Matches** (lista, szczegóły, create-flow),
w stylu zgodnym z aktualnym kodem aplikacji:

- Strony/widoki są możliwie **bezstanowe** (`ConsumerWidget`), a dane dostarczamy przez
  Riverpoda.
- Stan asynchroniczny: **`AsyncValue` + `AsyncValue.guard`** (jak w
  `PlayersNotifier`).
- Notifier → UseCase `.execute()` → Repository (interfejs domenowy) → Supabase repo.
- Uprawnienia UI oparte o `Squad.role` (owner/admin) z `squadDetailProvider`.

---

## Stories (źródło: `prd.md` 119–197)

### US-006: Lista meczy
- Wejście z kafla “Matches” na stronie squadu.
- Routing: `/squads/:squadId/matches`
- Lista z reużywalnym `MatchTile` (data + wynik).

### US-007: Utworz mecz (przycisk "+")
- "+" widoczne tylko dla **owner/admin**.
- Routing startowy: `/squads/:squadId/matches/draft`.
- `/matches/draft` to wybor graczy (legacy create page style) z akcja "Generate draft" prowadzaca do `/squads/:squadId/matches/create`, gdzie wybieramy/edytujemy propozycje przed utworzeniem meczu.

### US-008: Szczegóły meczu
- Routing: `/squads/:squadId/matches/:matchId`
- Widok zawiera: datę, wynik, składy drużyn oraz nawigację.

### US-009: Szybka nawigacja do gracza
- Kliknięcie gracza w składzie przenosi do:
  `/squads/:squadId/players/:playerId`
- Na MVP: może być **mock/placeholder** (zgodnie z story).

---

## Routing (GoRouter)

Aktualnie `core/app_router.dart` nie ma tras dla Matches. Plan:

- Dodac do `AppRoute`:
  - `matches`
  - `matchDetails`
  - `matchDraft` (selection `/matches/draft`)
  - `matchCreate` (draft results `/matches/create`)
  - (opcjonalnie) `playerDetails` jezeli jeszcze nie istnieje

- Dodac GoRoute'y:
  - `/squads/:squadId/matches` -> `SquadMatchesPage(squadId)`
  - `/squads/:squadId/matches/draft` -> `DraftSelectionPage(squadId)` (feature Draft)
  - `/squads/:squadId/matches/create` -> `DraftResultsPage(squadId, selectedPlayerIds)` (feature Draft)
  - `/squads/:squadId/matches/:matchId` -> `MatchDetailsPage(squadId, matchId)`
  - `/squads/:squadId/players/:playerId` -> placeholder (do czasu pelnego Players Details)

Integracja UX:
- Kafelek `Matches` w `SquadHomePage` (grid) powinien nawigowac do `/matches` zamiast pokazywac `coming soon`.
- Przycisk `+` (quick actions/Add match) prowadzi do `/squads/:squadId/matches/draft`.
- Po `Create Match` w `/matches/create` przechodzimy do `/matches/:matchId` i invalidujemy liste matches.
- Szczegoly UI dla `/matches/draft` + `/matches/create` sa opisane w `.ai/features/draft.md`.
---

## Kontrakt DB (źródło: `.ai/db_plan.md` 147–205)

### Tabele
- `matches`:
  - `match_id` (UUID, PK)
  - `squad_id` (FK)
  - `tournament_id` (nullable)
  - `score_type` (enum `match_score_type`, nullable)
  - `home_score`, `away_score` (nullable smallint)
  - `score_meta` (jsonb, default `{}`)
  - `created_at`

- `teams` (snapshot per match):
  - `team_id` (UUID, PK)
  - `match_id` (FK)
  - `side` (enum `side_enum`, home/away)
  - `name`, `color` (nullable)
  - `created_at`
  - UNIQUE `(match_id, side)`
  - UNIQUE `(match_id, team_id)` (dla FK w `team_players`)

- `team_players`:
  - `match_id` (FK)
  - `team_id`
  - `player_id` (FK → `players`, RESTRICT)
  - PK `(match_id, team_id, player_id)`
  - UNIQUE `(match_id, player_id)` (gracz nie może być w obu teamach)

### Uwaga o “snapshot”
Twoje notatki zakładały `MatchPlayer.name/score`. W obecnym planie DB te pola **nie
istnieją** w `team_players`.

Decyzje (MVP):
- **Nie dodajemy snapshotów** do `team_players`.
- `player.name` bierzemy zawsze **aktualne** z `players`.
- `player.score` na razie bierzemy **aktualne** z `players`, a w przyszłości // TODO: zasilic to score_history, gdy bedzie gotowe.
  będziemy je wyliczać na podstawie `score_history`.
---

## Model domenowy (Matches)

### Encje
Proponowane encje (feature-first: `features/matches/domain/...`):

- `Match`
  - `matchId`, `squadId`, `tournamentId?`
  - `scoreType?` (enum)
  - `homeScore?`, `awayScore?`
  - `scoreMeta` (`Map<String, dynamic>`)
  - `createdAt`
  - `homeTeam`, `awayTeam` (opcjonalnie w “list view” mogą być null i ładowane dopiero w details)

- `Team`
  - `teamId`, `matchId`
  - `side` (enum: home/away)
  - `name?`, `color?`
  - `players` (`List<Player>`) — encja z `features/players/domain/entities/player.dart`

> Nie tworzymy osobnej encji `MatchPlayer` w domenie Matches.
> Skład drużyn trzymamy jako `List<Player>`.

### Enumy
- `MatchScoreType`: `regular`, `penalties`, `walkover`, `cancelled`
  - mapowanie do DB enum `match_score_type`
- `Side`: `home`, `away`
  - mapowanie do DB enum `side_enum`

---

## Repozytorium (Domain) + Supabase (Infrastructure)

### `MatchRepository` (domain)
Interfejs (MVP + pod przyszłe story):

- `Future<List<Match>> getSquadMatches({required String squadId})`
  - dla listy wystarczy: `match_id`, `created_at`, `home_score`, `away_score`,
    `score_type`
  - **nie pobieramy teams** (teams są ładowane dopiero w `getMatch`)

- `Future<Match> getMatch({required String matchId})`
  - details: match + teams + team_players + odczyt graczy z `players`
    (żeby zbudować `Team.players` jako `List<Player>`)

- `Future<Match> createMatch({required String squadId, String? tournamentId, required Team homeTeam, required Team awayTeam})`
  - tworzy: `matches` + 2 rekordy `teams` + `team_players`

- `Future<void> deleteMatch({required String matchId})`

- `Future<Match> updateMatchScore({required String matchId, MatchScoreType? scoreType, int? homeScore, int? awayScore, Map<String, dynamic>? scoreMeta})`

- `Future<Match> updateMatchTeams({required String matchId, required List<String> homePlayerIds, required List<String> awayPlayerIds})`
  - implementacyjnie: zamiana rosterów jako “replace” (delete + insert) w `team_players`

- `Future<Team> updateTeam({required String matchId, required String teamId, String? name, String? color})`

> `Rematch` / `Redraw` traktujemy jako **use case’y aplikacyjne** (orchestracja),
> nie jako metody repo (repo powinno być “thin” i mapować na DB).

### `SupabaseMatchRepository` (infrastructure)
Wzorzec jak w `SupabasePlayerRepository`:

- provider:
  - `final matchRepositoryProvider = Provider<MatchRepository>((ref) => SupabaseMatchRepository(ref.read(supabaseProvider)));`
- obsługa błędów: `catch (e, stack) { _logger.severe(...); throw e.toFailure(); }`
- `Uuid().v4()` dla nowych `match_id` / `team_id`.

Sugestia query shape dla `getMatch`:
- `matches.select('match_id, squad_id, tournament_id, score_type, home_score, away_score, score_meta, created_at, teams(team_id, match_id, side, name, color, created_at, team_players(player_id))')`
- Alternatywa (łatwiejsze mapowanie): 2–3 osobne zapytania:
  - match row
  - teams rows
  - team_players rows + select `players` po `player_id in (...)`

---

## Use case’y (Application)

Każdy use case ma `.execute(...)` i Provider jak w Players.

### Read
- `GetSquadMatches` → `matchRepository.getSquadMatches`
- `GetMatch` → `matchRepository.getMatch`

### Write
- `CreateMatch`
  - input: `squadId`, `homePlayerIds`, `awayPlayerIds`, `teamName/color?`, `tournamentId?`
  - output: `Match`

- `DeleteMatch`
- `UpdateMatchScore`
  - // TODO: po wpisaniu wyniku wolamy logike score_history (ApplyMatchScoreToPlayersUseCase) i przeliczamy ranking graczy.
- `UpdateMatchTeams`
- `UpdateTeamColor` (i ewentualnie `UpdateTeamName`)

### Orchestracje (zależne od draft / create flow)
- `Rematch`
  - `GetMatch(matchId)` → `CreateMatch(...)` z tymi samymi rosterami (nowy match)
- `Redraw`
  - `GetMatch(matchId)` → nawigacja do create/draft z preselected players,
    a następnie `DeleteMatch(matchId)` (zgodnie z PRD)

> W MVP `UpdateMatchScore` nie aktualizuje jeszcze rankingów – to spina `score_history`
> (osobny plan w `score_history.md`).

---

## Presentation (Pages, Widgets, Controllers)

### Wspólne zasady UI
- Błędy wyświetlamy w widoku przez `SelectableText.rich` w kolorze czerwonym
  (bez SnackBarów).
- Puste stany obsługujemy w ekranie.
- `RefreshIndicator` dla listy.

### 1) `/matches` → `SquadMatchesPage`
Cel: lista + nawigacja do details + “+” dla owner/admin.

Stan:
- `SquadMatchesNotifier extends Notifier<AsyncValue<List<Match>>>`
  - `load(squadId)` → `AsyncValue.guard(() => useCase.execute(...))`
  - `refresh(squadId)` → deleguje do `load`

Widgety:
- `MatchTile` (re-używalny)
  - data meczu (format podobny do legacy: Today/Yesterday + fallback `dd.MM.yyyy HH:mm`)
  - wynik: dwa boxy jak w legacy (puste gdy brak wyniku)

Uprawnienia:
- w `SquadMatchesPage` watch:
  - `final squadAsync = ref.watch(squadDetailProvider(squadId));`
  - `canManage = squad.role == owner || admin`

### 2) `/matches/:matchId` → `MatchDetailsPage`
Cel: szczegóły meczu.

Stan:
- `MatchDetailsNotifier extends Notifier<AsyncValue<Match>>`
  - `load(matchId)`

UI:
- header: data + wynik + score_type
- sekcje: Home team / Away team
  - listy graczy jako `ListView.builder` 
  - klik na gracza → `/squads/:squadId/players/:playerId` (mock jeśli brak)
- (później) przyciski `Rematch`, `Redraw` tylko dla owner/admin

### 3) Draft flow (delegowane do featuru Draft)
- `/matches/draft` (selection) + `/matches/create` (propozycje + finalizacja) sa opisane w `.ai/features/draft.md`.
- Matches pilnuje wejscia (FAB/quick action -> `/matches/draft`) oraz wyjscia (po `Create Match` nawigacja do details + invalidacja listy).
- Poza orkiestracja i integracja use case`u `CreateMatch`, szczegoly UI naleza do zespolu Draft.

---

## Struktura plików (propozycja)

`app/lib/features/matches/`
- `domain/`
  - `entities/` (`match.dart`, `team.dart`)
  - `repositories/match_repository.dart`
- `application/`
  - `usecases/` (get/create/update/delete/rematch/redraw)
- `infrastructure/`
  - `repositories/supabase_match_repository.dart`
- `presentation/`
  - `pages/` (`squad_matches_page.dart`, `match_details_page.dart`, `create_match_page.dart`)
  - `controllers/` (`squad_matches_notifier.dart`, `match_details_notifier.dart`, `create_match_controller.dart`)
  - `widgets/` (`match_tile.dart`, `score_box.dart`, `team_roster_list.dart`)

---

## Iteracyjny plan implementacji (żeby nie robić “wszystkiego naraz”)

### Etap A — “Matches list MVP” (US-006)
- Routing + nawigacja z `SquadHomePage` do `/matches`
- Domain `Match` (wersja “list item”)
- Repo: `getSquadMatches`
- Use case: `GetSquadMatches`
- Notifier + page + `MatchTile`

### Etap B — “Match details read-only” (US-008 + US-009 mock)
- Routing `/matches/:matchId`
- Repo: `getMatch` (match + teams + players)
- Use case: `GetMatch`
- Notifier + `MatchDetailsPage`
- Klik na gracza → placeholder route

### Etap C - "Draft flow" (US-007)
- `/matches/draft` (selection) + `/matches/create` (propozycje + finalizacja) zgodnie z `.ai/features/draft.md`.
- Matches dostarcza routing, integracje na wejscie/wyjscie oraz `CreateMatchUseCase`.
- Repo: `createMatch`.
- Use case: `CreateMatch`.

### Etap D — “Write operations” (pod US-012/US-013/US-014/US-015 w kolejnych sprintach)
- `UpdateMatchScore`, `UpdateMatchTeams`, `UpdateTeamColor/Name`
- `Rematch`, `Redraw`
- Integracja z `score_history` (osobny feature plan)

---

## Ustalenia (po review)

- `player.name` i (na razie) `player.score` bierzemy 'na zywo' z `players`.
  W przyszlosci `player.score` w kontekscie meczu bedzie oparte o `score_history`.
- Robimy **dwie trasy**: `/matches/create` i `/matches/draft`.
- Quick actions “Add match” mile widziane, ale **nie priorytet** na MVP.


