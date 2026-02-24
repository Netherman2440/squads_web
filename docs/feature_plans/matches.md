
### Matches — plan implementacji (US-006…US-016)

Ten dokument opisuje **plan wdrożenia featuru Matches** (lista, szczegóły, create-flow, zarządzanie),
w stylu zgodnym z aktualnym kodem aplikacji:

- Strony/widoki są możliwie **bezstanowe** (`ConsumerWidget`), a dane dostarczamy przez Riverpod.
- Stan asynchroniczny: **`AsyncValue` + `AsyncValue.guard`**.
- Notifier → UseCase `.execute()` → Repository (interfejs domenowy) → Supabase repo.
- Uprawnienia UI oparte o `Squad.role` (owner/admin) z `squadDetailProvider`.

---

## Stories (źródło: `prd.md` 119–197 + update)

### US-006: Lista meczy
- Wejście z kafla “Matches” na stronie squadu.
- Routing: `/squads/:squadId/matches`
- Lista z reużywalnym `MatchTile` (data + wynik).
- Sortowanie: od najnowszych.

### US-007: Utworz mecz (przycisk "+")
- "+" widoczne tylko dla **owner/admin**.
- Routing startowy: `/squads/:squadId/matches/draft`.
- `/matches/draft` to wybór graczy (legacy create page style) z akcją "Generate draft" prowadzącą do `/squads/:squadId/matches/create`, gdzie wybieramy/edytujemy propozycje przed utworzeniem meczu.

### US-008: Szczegóły meczu
- Routing: `/squads/:squadId/matches/:matchId`
- Widok zawiera: datę, wynik, składy drużyn i kolory oraz dodatkowe przyciski na pasku (edit, redraw, rematch) dla admina.
- **UWAGA:** Każdy tile wyświetla nie `player.ranking` (aktualny), tylko ranking z `ranking_history` dla tego meczu (snapshot historyczny). Wyświetlamy siłę gracza w momencie rozgrywania meczu.
- Bazowo zawsze home team ma przy sobie kwadracik z kolorem białym, a away ma kolor czarny.

### US-009: Szybka nawigacja do gracza
- Kliknięcie gracza w składzie przenosi do: `/squads/:squadId/players/:playerId`

### US-010: Edycja meczu (Edit Mode)
- Jako admin mogę wejść w tryb 'edit'.
- Na pasku pojawiają się przyciski: Save, Cancel, Redraft, Add Player, Swap Teams, Delete Match.
- Tile zawodników stają się **draggable** - można je przeciągać pomiędzy drużynami (jak w `/matches/create`).
- Mogę zmienić kolor drużyny klikając w kwadracik i wybierając kolor z palety.
- **Swap Teams**: zamienia graczy miejscami (Home <-> Away) - tylko w UI, zapis przy Save.
- Edycja składów jest możliwa tylko przed wpisaniem wyniku.

### US-011: Dodawanie/Usuwanie graczy w edycji
- **Add Player**:
  - Otwiera szybką wyszukiwarkę graczy (overlay/modal).
  - Po wyszukaniu: przeciągamy (drag) gracza z wyszukiwarki do wybranej drużyny.
  - Logika: Dodanie gracza do meczu skutkuje utworzeniem wpisu w `ranking_history` (lub aktualizacją przy zapisie).
- **Remove Player**:
  - Usunięcie gracza z meczu skutkuje usunięciem jego wpisu w `ranking_history` dotyczącym tego meczu.

### US-012: Delete Match
- Usunięcie meczu powoduje usunięcie wszystkich powiązanych wpisów w `ranking_history`.
- Wywołuje przeliczenie rankingu graczy (revert zmian).

### US-013: Redraft (w trybie edycji)
- Dostępne dla admina tylko przed wpisaniem wyniku.
- Kliknięcie przenosi nas z powrotem do `/matches/draft` z **aktualnie wybranymi zawodnikami** (Available + Selected).
- Po przejściu całego flow Draftu i zatwierdzeniu ("Save/Update"), **aktualizujemy** obecny mecz nowymi składami (zamiast tworzyć nowy duplikat).
- Zmiany aplikują się dopiero po zatwierdzeniu w flow draftu (nie usuwamy starego meczu od razu po kliknięciu Redraft).

### US-014: Rematch
- Dostępne z poziomu detali (nie w trybie edit).
- Tworzy **nowy** mecz z tymi samymi składami, ale zamienionymi stronami (Home <-> Away).
- Nawigacja do `/matches/:newMatchId`.

### US-015: Update match score (Wpisanie wyniku)
- Jako admin chcę móc wpisać/zmienić wynik meczu.
- Aktualizacja wyniku powoduje wywołanie logiki `Ranking History`:
  - Obliczenie delty rankingu.
  - Aktualizacja wpisów w `ranking_history`.
  - Aktualizacja `player.ranking` (poprzez dodanie/odjęcie różnicy).
- Po wpisaniu wyniku nie można już edytować składów.
- Wynik można zmienić tylko wtedy, gdy nie istnieje nowszy mecz z wpisanym wynikiem.
- **Obsługa starych meczy**:
  - Można edytować wynik meczu z przeszłości.
  - Zmiana w starym meczu aktualizuje `player.ranking` o różnicę delty (np. stara delta +2, nowa 0 -> ranking -2).
  - **Note**: Wpisy w `ranking_history` dla *późniejszych* meczy (chronologicznie nowszych) zachowują swoje historyczne wartości `ranking` (snapshoty), co jest akceptowalne (pokazują stan wiedzy "na wtedy"), mimo że aktualny ranking gracza uległ zmianie.
- **Warning**: Jeśli różnica w rankingu między drużynami jest > `appConfig.rankingDiffWarning` (np. 10%), pokazujemy warning: "Wybrane drużyny są nierówne, na pewno chcesz wpisać wynik?".

### US-012 Update match score 
- Jako admin chce móc zmienić wynik meczu
- Aktualizacja wyniku meczu powoduje:
- to że nie mogę już dłużej edytować drużyn (po kliknięciu edit od razu nie widzę redraft i add player,)
- wywołuje to aktualizację ranking history wszystkich graczy którzy brali udział

### US-013 Squad ranking settings
- Jako admin chce mieć kontrolę nad tym w jaki sposób aktualizowany jest ranking graczy 
- chce mieć kontrolę nad tym:
0) CZY WGL RANKING POWINIEN SIĘ ZMIENIAĆ
a) czy zmiana ma być różna dla doświadczonych graczy i dla nowych czy wszyscy zawodnicy z jednej drużyny dostają taką samą change do rankingu.
b) jak mocno powinnien się zmieniać ranking per bramka różnicy

chciałbym to przedstawić jako interaktywną sekcję wewnątrz Danger Zone
toggle do zmiany opcji a)
 slider z 3 opcjami pod b)
- mała zmiana
- deffaut 
- big change
nad sliderem pokazuje nam średnią zmianę rankingu / branka różnicy dla naszych ustawień
ta zmiana aktualizuje się przy każdej zmianie wartości w tej sekcji
zmiana tych ustawień nie wywołuje od razu business logic, buimy specjalnie kliknąć przycisk Save


### Squad ranking explenation
- Jako użytkownik gdy najade w  player details na player.ranking mogę kliknąć w ikonę informacji
- Kliknięcie pokazuje mi kartę informacyjną o tym jak ranking jest obliczany. 
-karta jest parametryzowana przez ustawienia składu i w zależności od tych ustawień wyświetla inną zawartość

###Calculate player score
Obliczamy zmianę rankingu zgodnie z wzorem:

(home_score - away_score ) * [changeMultiplier]

gdzie 
changeMultiplier = [numerator] / [denominator]

[numerator] - ustalony mnożnik w ustawieniach. Do wyboru jest 0.5, 1, 2, 

[denominator] = 1 ( jeśli change ma być równy dla nwoych i starych) albo [player.matches.count (minimum 1)] * appConfig.changeFactor = 0.2f.

### Update player ranking
- chce zaktualizować wynik gracza aby móc balansować drużyny
- aktualizacja przebiega zawsze zgodnie z ustalonym wzorem dla danego skłądu 



### Zabezpieczenia update match score:
-nie da sie zaktualizować wyniku meczu jeśli istnieje nowszy mecz z już wpisanym wynikiem ( jeśli ten mecz nei miał wcześniej wpisanego wyniku)
- jeśli różnica w rankingu między drużynami jest > appconfig.scorewarning ( 10 ) to pokazujemy warning w stylu:
"Wybrane drużyny są nie równe, na pewno chcesz wpisać wynik?" coś w tym stylu


---

## Routing (GoRouter)

Aktualnie `core/app_router.dart` nie ma tras dla Matches. Plan:

- Dodac do `AppRoute`:
  - `matches`
  - `matchDetails`
  - `matchDraft` (selection `/matches/draft`) done
  - `matchCreate` (draft results `/matches/create`) done 
  - (opcjonalnie) `playerDetails` done

- Dodac GoRoute'y:
  - `/squads/:squadId/matches` -> `SquadMatchesPage(squadId)`
  - `/squads/:squadId/matches/draft` -> `DraftSelectionPage(squadId)` (feature Draft) /done
  - `/squads/:squadId/matches/create` -> `DraftResultsPage(squadId, selectedPlayerIds)` (feature Draft) /done
  - `/squads/:squadId/matches/:matchId` -> `MatchDetailsPage(squadId, matchId)`
  - `/squads/:squadId/players/:playerId` -> placeholder (do czasu pelnego Players Details) /done

Integracja UX:
- Kafelek `Matches` w `SquadHomePage` (grid) powinien nawigowac do `/matches` zamiast pokazywac `coming soon`.
- Przycisk `+` (quick actions/Add match) prowadzi do `/squads/:squadId/matches/draft`. /done
- Po `Create Match` w `/matches/create` przechodzimy do `/matches/:matchId`.
- Szczegoly UI dla `/matches/draft` + `/matches/create` sa opisane w `.ai/features/draft.md`. /done
---

## Kontrakt DB

### Tabele
- `matches`:
  - `match_id` (UUID, PK)
  - `squad_id` (FK)
  - `tournament_id` (nullable)
  - `score_type` (enum `match_score_type`, nullable)
  - `home_score`, `away_score` (nullable smallint)
  - `score_meta` (jsonb, default `{}`)
  - `created_at`

- `teams`:
  - `team_id` (UUID, PK)
  - `match_id` (FK)
  - `side` (enum `side_enum`, home/away)
  - `name`, `color` (nullable)
  - `created_at`
  - UNIQUE `(match_id, side)`

- `team_players`:
  - `match_id` (FK)
  - `team_id`
  - `player_id` (FK → `players`, RESTRICT)
  - PK `(match_id, team_id, player_id)`
  - UNIQUE `(match_id, player_id)`

Dodatkowe kolumny w `squads` (do ustawień):
- `ranking_enabled` (bool, default true)
- `ranking_multiplier` (double, default 1.0)
- `use_experience_factor` (bool, default true)

---

## Model domenowy (Matches)

### Encje
- `Match`
  - `matchId`, `squadId`
  - `scoreType?`
  - `homeScore?`, `awayScore?`
  - `scoreMeta`
  - `createdAt`
  - `homeTeam`, `awayTeam` (Team)

- `Team`
  - `teamId`, `matchId`
  - `side` (enum: home/away)
  - `name?`, `color?`
  - `players` (`List<Player>`)

### Enumy
- `MatchScoreType`: `regular`, `penalties`, `walkover`, `cancelled`
- `Side`: `home`, `away`

---

## Repozytorium (Domain) + Supabase (Infrastructure)

### `MatchRepository` (domain)
Interfejs (MVP + pod przyszłe story):

- `Future<List<Match>> getSquadMatches({required String squadId})`
  - dla listy wystarczy: `match_id`, `created_at`, `home_score`, `away_score`,
    `score_type`
  - **nie pobieramy teams** (teams są ładowane dopiero w `getMatch`)

- `Future<Match> getMatch({required String matchId})` //albo =>MatchDeatils
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
> `Redraw` aktualizuje istniejący mecz (podmiana rosterów), bez usuwania rekordu meczu.

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


### RankingRepository
dodac metody
-deleteMatchRankingEntry 
-updateMatchRankingEntry

---

## Use case’y (Application)

Każdy use case ma `.execute(...)` i Provider jak w Players. 
i nazewnictwo w stylu get_squad_matches_use_case daje klase GetSquadMatchesUseCase

### Read
- `GetSquadMatches` → `matchRepository.getSquadMatches`
- `GetMatch` → `matchRepository.getMatch`

### Write
- `CreateMatch`
  - input: `squadId`, `homePlayerIds`, `awayPlayerIds`, `teamName/color?`, `tournamentId?`
  -trzeba tutaj wywołac oprcz matchRepo.createMatch
  to jeszcze rankingRepo.createMatchRankingEntry
  - output: `Match` 


- `DeleteMatch`
  - Woła `matchRepo.deleteMatch`.
  - Woła `rankingRepo.deleteMatchRankingEntry`.
  - Aktualizuje `player.ranking` (odejmuje zmiany wynikające z usuniętego meczu, jeśli były).

- `UpdateMatchScore`
  - Update wyniku w `matchRepo`.
  - Dla każdego gracza:
    - Pobiera wpis z historii (entry) dla tego meczu.
    - Liczy nową deltę.
    - Aktualizuje wpis w historii.
    - Aktualizuje `player.ranking += (newDelta - oldDelta)`.
  - Logika obsługuje edycję starych meczy (aktualizuje bieżący ranking o różnicę, pozostawiając historyczne snapshoty w późniejszych meczach bez zmian).

- `UpdateMatchTeams` (używany przez Save po Swap/Add/Remove)
  - Update składów w `matchRepo`.
  - Jeśli mecz ma już wynik -> nie możliweZ
  get players for match (aktualnych)
  - dla każdego gracza sprawdzamy czy ma rankinge entry
  - Jeśli dodajemy gracza -> `createMatchRankingEntry`.
  - Jeśli usuwamy gracza -> `deleteMatchRankingEntry` (dla tego gracza).

---

## Presentation (Pages, Widgets, Controllers)

### Wspólne zasady UI
- Błędy wyświetlamy w widoku przez `SelectableText.rich` w kolorze czerwonym
  (bez SnackBarów).
- Puste stany obsługujemy w ekranie.
- `RefreshIndicator` dla listy.
-consumer widgety, riverpod, strony raczej są stateless, tylko notifierami przeładowujemy kontent

### 1) `/matches` → `SquadMatchesPage`
Cel: lista + nawigacja do details + “+” dla owner/admin.
Sortujemy je po dacie i mamy wybór najnowsze najstarsze 
Stan:
- `SquadMatchesNotifier extends Notifier<AsyncValue<List<Match>>>`
  - `load(squadId)` → `AsyncValue.guard(() => useCase.execute(...))`
  - `refresh(squadId)` → deleguje do `load`

Widgety:
- `MatchTile` (re-używalny: przyda nam się do /players/$playerId/matches)
  - data meczu (format podobny do legacy: Today/Yesterday + fallback `dd.MM.yyyy HH:mm`)
  - wynik: dwa boxy jak w legacy (puste gdy brak wyniku)


Uprawnienia:
- w `SquadMatchesPage` watch:
  - `final squadAsync = ref.watch(squadDetailProvider(squadId));`
  - `canManage = squad.role == owner || admin`

### 2) `/matches/:matchId` → `MatchDetailsPage`
- `MatchDetailsNotifier`.
- Header: Wynik, Data.
- Lists: Home / Away Players.
- Tryb Edit (Admin):
  - Drag & Drop zawodników.
  - Floating/Action buttons: Save, Cancel, Add Player.
- Warning przy zapisie wyniku (jeśli nierówne rankingi).

Stan:
- `MatchDetailsNotifier extends Notifier<AsyncValue<Match>>`
  - `load(matchId)`

UI:
- header: data + wynik + score_type (score_type na razie nie pokazujmy)
- sekcje: Home team / Away team
  - listy graczy jako `ListView.builder` 
  - klik na gracza → `/squads/:squadId/players/:playerId`
-  przyciski `Rematch`, `Redraw`, `Edit` tylko dla owner/admin
- w stanie Edit tak jak w stories(nie pamiętam numeru) mamy dragable players i przycisk addplayer i save cancel

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
- [x] Routing + nawigacja z `SquadHomePage` do `/matches`
- [x] Domain `Match` (wersja “list item”)
- [x] Repo: `getSquadMatches`
- [x] Use case: `GetSquadMatches`
- [x] Notifier + page + `MatchTile`

### Etap B — “Match details read-only” (US-008 + US-009 mock)
- [x] Routing `/matches/:matchId`
- [x] Repo: `getMatch` (match)
- [x] Team repo: `getMatchTeams` (teams + players + snapshot rankingu z `ranking_history`)
- [x] Use case: `GetMatch`
- [x] Notifier + `MatchDetailsPage`
- [x] Klik na gracza → `/squads/:squadId/players/:playerId` (zmiana URL)

### Etap C - "Draft flow" (US-007)
- [x] `/matches/draft` (selection) + `/matches/create` (propozycje + finalizacja) zgodnie z `.ai/features/draft.md`.
- [x] Matches dostarcza routing, integracje na wejscie/wyjscie oraz `CreateMatchUseCase`.
- [x] Repo: `createMatch`.
- [x] Use case: `CreateMatch`.
- [x] Invalidacja listy matches po utworzeniu (żeby nowy mecz był widoczny po powrocie)

### Etap D — “Write operations” (pod US-012/US-013/US-014/US-015 w kolejnych sprintach)
- [x] `UpdateMatchScore`
- [x] `UpdateMatchTeams` (w tym Add/Remove przez update rosterów)
- [x] `Rematch`
- [x] `Redraw` 
- [ ] `UpdateTeamColor/Name` (nie zaimplementowane)
- [x] Integracja z `ranking_history` (osobny feature plan)
- [x] `DeleteMatch` (implementacja usunięcia meczu i cofnięcia rankingu)
- [x] Invalidacja ranking history po update score (odświeżenie Player Details / graph)
- [ ] Squad Settings z wzorem obliczania ranking update
---

## Ustalenia (po review)

- `player.name` bierzemy 'na zywo' z `players`.
- `player.ranking` w **Match Details** to snapshot z `ranking_history` (obecnie: `ranking_history.ranking + change`).

---

## Implementacja — dodatkowe poprawki UX (po testach)

- Match Details:
  - tryb edit ma akcje w AppBar (Save/Cancel)
  - Delete jako ikona w trybie **no-edit** obok ołówka
  - score nie pozwala wpisać wartości ujemnych (tylko cyfry)
  - drag&drop pomiędzy drużynami działa
  - w trakcie drag pojawia się drop-zone z “X” do usuwania zawodnika z meczu (UI)
  - Add Player: panel z wyszukiwaniem i listą dostępnych graczy (spoza meczu) + drag do drużyny
  - przy nazwie drużyny jest kwadracik z kolorem + efektywny ranking drużyny (jak w draft)

- Redraft:
  - `/matches/draft` przyjmuje `selectedIds` oraz `matchId` (jeśli podane, startuje od razu z Selected)
  - `/matches/create` przyjmuje `matchId`; jeśli jest, to finalizacja robi update istniejącego meczu zamiast tworzyć nowy
