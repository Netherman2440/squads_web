
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

## Stories (źródło: `prd.md` 119–197) //trochę też dopisałem

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
- Widok zawiera: datę, wynik, składy drużyn i kolory oraz dodatkowe przyciski na pasku edit, redraw i rematch.
- UWAGA: każdy tile wiświetla nie player.ranking tylko match ranking history entry.ranking !!! czyli wyświetlamy taki ranking jaki gracz miał przed tym meczem a nie jego aktualny ranking
- bazowo zawsze home team ma przy sobie kwadracik z kolorem białym a away ma kolor czarny 
### US-009: Szybka nawigacja do gracza
- Kliknięcie gracza w składzie przenosi do:
  `/squads/:squadId/players/:playerId`

Rematch:
po kliknięciu 

### Us 010: Edit
- Jako admin mogę wejść w tryb 'edit'
- na pasku pojawiają mi się wtedy przyciski do zapisu, cofnięcia zmian, przycisk redraft, add player, swap teams DELETE MATCH
- tile zawodników stają się dragable można je przeciagać pomiędzy drużynami jak w /matches/create
- mogę wpisać wynik 
- mogę zmienić kolor drużyny klikając w kwadracik  i wybrać kolor z palety 
- kliknięcie swap teams zamieni graczy miejscami away <-> home 
### US-011: Delete match
- usunięcia gracza z meczu powinno skutkować usunieciem tez jego wpisu w score history

### US 012 Add player 
- otwiera mi się szybka wyszukiwarka jakiego gracza bym chciał dodać
- idealne flow: po kliknięciu gracza wchodzimy 'drag' - wyszukiwarka staje się mocno przezroczysta a nowego gracza możemy przeciągnąć do jednej lub drugiej drużyny
- jesli użytkownik tylko kliknie to nic się nie dzieje, musi rozpocząć drag żeby przenieśc gracza z wyszukiwarki do match details
- w logice powinno to dodać w score history odpowiedni wpis dla nowego gracza

### US Rm Player
- usunięcie gracza powinno skutkować również usunięciem jego wpisu w score hisotry dotyczącym tego meczu

### US-011: Redraft
- Jako admin przed wpisaniem wyniku mam możliwość kliknięcia przycisku redraft
- Kliknięcie go przenosi nas z powrotem do /matches/draft z aktualnie wybranymi zawodnikami  i przenosi tych zawodników od razu do Selected players
- (jesli wcześniej dodałem gracza do meczu to ten gracz też trafia do Selected Players!)


### US-012 Update match score 
- Jako admin chce móc zmienić wynik meczu
- Aktualizacja wyniku meczu powoduje:
- to że nie mogę już dłużej edytować drużyn ( po kliknięciu edit od razu nie widzę redraft i add player,)
- wywołuje to aktualizację score history wszystkich graczy którzy brali 

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

## Kontrakt DB (źródło: `.ai/db_plan.md` 147–205)

//todo
Dodać kolumny do `squads`:
- rankingUpdate (bool) deffault true
- changeMultiplier (pewnie jakieś double)
- (jak nazwać kolumnę mówiącą o róznych zmianach dla doświadczonych i nowych graczach)


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
  - UNIQUE `(match_id, team_id)` (dla FK w `team_players`)

- `team_players`:
  - `match_id` (FK)
  - `team_id`
  - `player_id` (FK → `players`, RESTRICT)
  - PK `(match_id, team_id, player_id)`
  - UNIQUE `(match_id, player_id)` (gracz nie może być w obu teamach)

---

## Model domenowy (Matches)

### Encje
Proponowane encje (feature-first: `features/matches/domain/...`):

Match Score
MatchScoreType
tuple[int,int] score //home:away
dict meta data

- `Match`
  - `matchId`, `squadId`, `tournamentId?`
  - `scoreType?` (enum)
  - `homeScore?`, `awayScore?` => score: MatchScore
  - `scoreMeta` (`Map<String, dynamic>`)
  - `createdAt`
  - `homeTeam`, `awayTeam` (opcjonalnie w “list view” mogą być null i ładowane dopiero w details)

- `Team`
  - `teamId`, `matchId`
  - `side` (enum: home/away)
  - `name?`, `color?`
  - `players` (`List<Player>`) — encja z `features/players/domain/entities/player.dart`

MatchDetails:Match //nie wiem czy to dobry pomysł ale możemy też to tak rozdzielić
- `homeTeam`, `awayTeam` (opcjonalnie w “list view” mogą być null i ładowane dopiero w details)

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
  - output: `Match` //może zwracać to ale przy przejściu do details i tak potrzebujemy teams więc jeśli match details to wtedy nie wiem co tu zwrócić


- `DeleteMatch`
  tutaj podobnie - pamiętajmy oprócz matchrepo to update `player.ranking -= entry.change` i rankingRepo.delete(`entry`)

  
- `UpdateMatchScore`
  - update match score, for each player:
  get ranking for this match (!!! entry.Ranking a nie current ranking!!!) calculate delta, update ranking history 
  calculate `player.ranking += entry.change`, update playerRanking
  - to bardzo ważne żeby brać ranking dla danego meczu, bo może być case że wpisujemy wynik do meczu z przeszłości. Wtedy żeby przypadkiem nam się nie spushował cały stary ranking jako akutalny .


- `UpdateMatchTeams`
- `UpdateTeamColor` (i ewentualnie `UpdateTeamName`)
-

### Orchestracje (zależne od draft / create flow)
- `SwapTeams`
  - → `matchRepository.getMatch` -> udpate teams (zamieniając players), 
- `Rematch`
  - `GetMatch(matchId)` → `CreateMatch(...)` z tymi samymi drużynami, zamienionymi miejscami (nowy match), rankingRepo.createMatchEntry
- `Redraw`
  - `GetMatch(matchId)`  =>  nawigacja do create/draft z preselected players,
    a następnie `DeleteMatch(matchId)` (zgodnie z PRD) 

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
Cel: szczegóły meczu.

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

- `player.name` i  `player.ranking` bierzemy 'na zywo' z `players`.



