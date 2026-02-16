
### Draft — plan implementacji (US-010…US-011)

Ten dokument opisuje **plan wdrożenia featuru Draft** (generowanie propozycji drużyn
oraz utworzenie meczu z wybranej propozycji), zgodnie z ustaleniami w
`.ai/features/matches.md`:

- Flow zaczyna sie na `/squads/:squadId/matches/draft` (wybor graczy) i konczy na `/squads/:squadId/matches/create` (podglad propozycji + finalizacja).
- Draft korzysta z istniejacych encji **`Player`** (bez `MatchPlayer`).
- Drafty **nie sa zapisywane w DB** (to nadal obiekt tymczasowy/obliczeniowy).
- Algorytm jest **deterministyczny** (bez seed/losowosci).
- Stan w UI: **Riverpod + AsyncValue + AsyncValue.guard** (jak w `PlayersNotifier`).

---

## Stories (źródło: `prd.md` US-010, US-011)

### US-010: Draft zbalansowanych drużyn
- “Mogę swobodnie dodawać i usuwać graczy do draftu.”
- “Z wybranej puli graczy losowanych jest do 20 propozycji…”
- “Propozycje są posortowane od najlepszej do najgorszej.”
- “Propozycje są deterministyczne, można je odtworzyć.”

### US-011: Utworzenie meczu z draftu
- “Wybór propozycji tworzy mecz z przypisanymi drużynami.”

Referencja UI (legacy):
- `DraftPage` generuje drafty i przechodzi do `CreateMatchPage`.
- `CreateMatchPage` pokazuje jedną propozycję naraz, ma strzałki lewo/prawo,
  reset zmian przy przełączeniu, edycję składów i przycisk “Create Match”.

---

## Routing i integracja z Matches

Docelowe trasy (ustalone):
- `/squads/:squadId/matches/draft`
  - ekran wyboru graczy (available/selected) + search + akcja przejscia do draftu.
  - tutaj prowadzi przycisk `+` z `/squads/:squadId/matches`.
- `/squads/:squadId/matches/create`
  - ekran propozycji draftu z mozliwoscia edycji rosterow i przyciskiem `Create Match`.
  - korzysta z wyniku `createDraftUseCase` dla przekazanych graczy.

Kontrakt nawigacji i odpowiedzialnosci:
- `matches/draft` po kliknieciu "Generate draft" przekazuje `squadId` oraz `selectedPlayerIds` (IDs, a odczyt Playerow robimy z providerow Players) do `matches/create`.
- `matches/create` po "Create Match" wywoluje `CreateMatchUseCase` (Matches) z aktualnym stanem obu list i po sukcesie przechodzi do `/squads/:squadId/matches/:matchId`.
- Feature Draft konczy sie na wyborze finalnego zestawu druzyn; przejscie do szczegolow meczu jest juz czescia featuru Matches.
---

## Model domenowy (Draft)

Draft to czysta logika generowania propozycji.

### Encje
- `Draft`
  - `homePlayers: List<Player>`
  - `awayPlayers: List<Player>`
  - `homeTotalScore: double` (suma `player.score`)
  - `awayTotalScore: double`


---

## `DraftRepository` (Domain) i implementacja (Infrastructure)

### Interfejs domenowy
- `Future<List<Draft>> createDraft({required List<Player> players, int limit = 20})`

### Infrastructure: brak DB
Nie tworzymy tabel i migracji. Implementacja to lokalny “engine”:
- `DeterministicDraftEngine` / `LocalDraftRepository`
  - wejście: lista `Player` (z aktualnymi `score`)
  - wyjście: lista `Draft`

### Deterministyczny algorytm (MVP/target)

Wymaganie: brak losowości, powtarzalność wyników.

1) **Normalizacja wejścia**
- sortujemy wejściowych graczy deterministycznie (np. po `playerId`)

2) **Limit wejścia**
- dla N > 16: zwracamy błąd/Failure i UI pokazuje komunikat o limicie
  (zachowanie jak w story o limicie; szczegóły UX w Presentation)

3) **Generowanie podziałów**
- przy N parzystym: rozmiary drużyn \(k = N/2\)
- przy N nieparzystym: dopuszczamy nierówne rozmiary drużyn i zmieniamy sposób
  liczenia “mocy” drużyny do oceny balansu (szczegóły niżej)

Technicznie:
- enumerujemy kombinacje wyboru \(k\) graczy do home team,
  away team to “reszta”
- aby uniknąć duplikatów (home/away swap):
  - kanonizacja: np. wymagamy, by “najmniejszy playerId” zawsze należał do home

4) **Scoring propozycji**
- `homeTotalScore` i `awayTotalScore` trzymamy w obiekcie `Draft`.
- Do sortowania liczymy “effective total” (wartość tymczasowa):
  - **N parzyste**: `effective = sum(player.score)`
  - **N nieparzyste**: `effective = sum(player.score) - min(player.score)`
    (nie bierzemy pod uwagę najsłabszego zawodnika w drużynie)
- “Balance” liczymy jako wartość tymczasową do rankingu:
  - `balance = abs(effectiveHome - effectiveAway)`

5) **Sortowanie i tie-break**
- sort: `balance ASC` (liczone tylko na potrzeby rankingu, nie przechowujemy pola diff)
- tie-break deterministyczny:
  - np. lista ID w home jako string (zawsze posortowana) `ASC`

6) **Top-N**
- zwracamy do `limit` (domyślnie 20)

Złożoność:
- dla 16 graczy: \(C(16,8)=12870\) propozycji — OK na client-side.

### MVP fallback (jeśli chcemy szybko UI)
Na start możemy zwrócić 1–3 propozycje:
- split na pół po sortowaniu (lub prosty “zig-zag” po score),
żeby szybciej spiąć UX. Docelowo jednak trzymamy algorytm powyżej.

---

## Use case’y (Application)

- `CreateDraftUseCase`
  - `execute({required List<Player> players}) -> List<Draft>`
  - wywołuje `DraftRepository.createDraft(...)`

> `CreateMatchUseCase` należy do featuru Matches; Draft tylko go używa w UI.

---

## Presentation (UI)

### 1) `/matches/draft` - DraftSelectionPage
Cel: odtworzyc legacy UX wyboru zawodnikow przed wygenerowaniem draftu.
- `available players` + `selected players` (tap/drag pomiedzy listami)
- search dla listy available
- layout responsywny: narrow -> selected na gorze, available na dole; wide -> available po lewej, selected po prawej
- AppBar: tytul "Draft" + akcja "Generate draft" aktywna tylko gdy `selectedPlayerIds.isNotEmpty`

Stan i logika:
- `DraftSelectionController extends Notifier<AsyncValue<DraftSelectionState>>`
  - `selectedPlayerIds`
  - `searchQuery`
  - `availablePlayers` (najlepiej reuse `playersNotifierProvider` / `GetSquadPlayersUseCase`)
  - metody: `loadPlayers(squadId)`, `togglePlayer(playerId)` (walidacja limitu <= 16), `setSearchQuery(...)`, `clearSelection()`
  - `generateDraft()` -> `context.go('/squads/$squadId/matches/create', extra: selectedPlayerIds);`
- UI pokazuje komunikat limitu >16 jeszcze przed przejsciem na kolejny ekran

### 2) `/matches/create` - DraftResultsPage
Inspiracja: legacy `CreateMatchPage`.
- strzalki lewo/prawo zmieniaja propozycje
- przy zmianie propozycji resetujemy edycje do oryginalu
- dwa scrollowalne sklady obok siebie (wide) lub jeden pod drugim (narrow)
- `Create Match` bierze aktualny stan kolumn

Struktura:
- AppBar: tytul "Draft" + akcja "Create Match"
- Gora: nawigacja propozycji: `<< [Draft i z N] >>`
- Nad rosterami: podsumowanie `Home total` i `Away total`
- Body: dwa panele, drag & drop, wypis graczy

Stan:
- `DraftSessionNotifier extends Notifier<AsyncValue<DraftSessionState>>`
  - `proposals: List<Draft>`
  - `selectedIndex: int`
  - `home: List<Player>`
  - `away: List<Player>`
  - brak edycji nazw/kolorow w MVP
  - `load({required squadId, required selectedPlayerIds})` -> `AsyncValue.guard(() => createDraftUseCase.execute(players: ...))` i inicjalizuje `home/away` stanem z proposal[0]
  - `selectProposal(index)` resetuje `home/away`
  - `movePlayer(playerId, toSide)` / `swapPlayer(...)`
  - `createMatch()` -> `CreateMatchUseCase.execute(...)`, po sukcesie: `context.go('/squads/$squadId/matches/$matchId')` + invalidacja listy (`squadMatchesProvider`)

Obsluga bledow i empty state:
- `AsyncValue.error`: pokazujemy `SelectableText.rich` (czerwony tekst)
- `proposals.isEmpty`: komunikat "Brak propozycji - wroc do /squads/:squadId/matches/draft"
- limit >16: dedykowany komunikat (rowniez gdy stan wejscia zostal podmieniony na wiekszy)

Uprawnienia:
- oba ekrany dostepne tylko dla owner/admin (spojne z Matches).
---

## Integracja z "dodawaniem/odejmowaniem graczy do draftu" (US-010)

Ta czesc jest realizowana glownie w `/matches/draft`:
- tam uzytkownik dobiera pule graczy (selected/available) i pilnuje limitu + walidacji
- `/matches/create` jest juz "wynikiem" dla przygotowanej puli (edycja rosterow + Create Match)

Opcjonalnie (nie MVP):
- na `/matches/create` dodajemy akcje "Back to selection" jezeli chcemy latwo zmienic pule bez recznego cofania.
---

## Iteracyjny plan implementacji

### Etap A - `/matches/draft` (selection)
- routing `/matches/draft`
- `DraftSelectionController` + ladowanie graczy z Players
- walidacja limitu <=16 i akcja "Generate draft" przekazujaca IDs do `/matches/create`

### Etap B - `/matches/create` skeleton (bez DnD)
- routing `/matches/create`
- `DraftSessionNotifier` + ladowanie proposals
- nawigacja strzalkami, reset zmian, stub `Create Match`

### Etap C - Deterministyczny engine + top 20
- implementacja enumeracji kombinacji + sort/tie-break
- limit >16 + komunikat (spojny miedzy ekranami)

### Etap D - Edycja skladow (drag & drop)
- przenoszenie zawodnikow miedzy listami
- walidacja: gracz nie moze byc w obu teamach

### Etap E - Integracja `Create Match`
- wywolanie `CreateMatchUseCase` z aktualnymi rosterami
- invalidacja listy matches + nawigacja do `/matches/:matchId`
---

## Ustalenia (po review)

- Dopuszczamy **nieparzystą** liczbę graczy.
  - Ranking draftów liczymy na “effective total”, gdzie z sumy drużyny
    odejmujemy wynik najsłabszego zawodnika (żeby wyrównać wpływ dodatkowego gracza).
- W MVP **nie edytujemy** `teamAName/teamBName` na draft screenie.
  - Domyślne nazwy: “FC Biali” i “Czarni United”.
  - Edycja nazw/kolorów dopiero później w match view (US-013).




-----

DRAFT REFACTOR:

Musimy dostosować draft do zwiększonych potrzeb:

1. Użytkownik chce dzielić daną pulę graczy na więcej równych drużyn niż tylko dwie .

2. Użytkownik chce aby przy wyborze były brane pod uwagę pozycje zawodników.

3. Użytkownik chce móc zdecydować że jacyś zawodnicy muszą być razem w składzie a inni muszą być przeciwko sobie

// NEwton + Gosper
//todo: gosper hack (iterowanie przez symbole newtonowskie zamiast przez 2^N)

Żeby ograniczyć ilość przeglądanych opcji w combinatory service chcemy ograniczyć się do gosper hack.

Mając wszystkie kombinacje następnym krokiem jest ocena składów.

Definicje
team score - sumaryczny ranking wszystkich graczy w danej drużynie (z uwzględnieniem rezerwy)

avg team score - ranking "idealnej drużyny " czyli all players score / 2 

avg player - średni ranking w danym meczu

waga drużyny:
To dzięki niej będziemy w stanie wziąć pod uwagę pkt. 2 i 3 w user stories.
Obliczana jest na podstawie doboru wszystkich zawodników do danej drużyny.
Na wejściu do algorytmu otrzymujemy dwie listy z zasadami:
- lista z grupami zawodników którzy muszą być RAZEM
- lista z grupami zawodników którzy muszą być PRZECIWKO SOBIE



Każdy zawodnik bazowo ma wagę 1.
Za każdą niespełnioną regułę durzycaym 100 do wagi całego podziału?

edge case: mam w regule 3 graczy, wszyscy chcą być przeciwko sobie, a mam tylko dwie drużyny, 
wtedy dla jednego gracza reguła jest spełniona - jemu się to podoba
solution: - blokujemy designem dodawanie takich reguł. Jeśli tworzymy podział na dwie drużyny do reguł 'przeciwko' można dodać maksymalnie 2 graczy.
Podobnie ograniczamy reguły 'razem' - w jednej regule może być maksymalnie tylko zaowdników ile ostatecznie będzie w jednym składzie - czyli np. jak wybieramy 3 skład y i mamy 15 zawodników to w jednej regule razem może byc tylko 5 graczy.

Do tego pozycje.
Jeśli w danej drużynie znajduje się już zawodnik z daną pozycją (również bierzemy pod uwagę 'none' czyli brak pozycji jako pozycję)
wtedy waga tego zawodnika rośnie o tyle ilu już jest zawodników na takie pozycji

np. pierwszy bramkarz w składzie do waga 1, drugi to 2 trzeci to 3 itd. Podbnie - pierwszy gracz bez pozycji to waga 1, drugi 2 itd.

Ocena podziału to:

- suma odchyłu team score od średniej [ abs( team A score - avg team score) + aabs(team B score - avg team score) + ... ]
POMNOŻONA RAZY:
-  sumaryczna waga wszystkich drużyn

w przypadku remisów decyduje:
- suma kwadratów różnic między graczami na poszczególnych pozycjach w rankingu:
(ranking najlepszego gracza A - ranking najlepszego gracza B)^2 + (ranking drugiego gracza A - ranking drugiego gracza B)^2 + ...


Przechowujemy tylko current 20 najlepszych zestawień. - Jeśli jakieś jest słabe to skip i lecimy dalej



---

W taki sposób jesteśmy gotowi na:
- więcej drużyn
- pozycje graczy
- grupy reguł


Chce żebyś zaimplementował ten algorytm w `app/lib/features/draft/infrastructure/repositories/combinatory_draft_repository.dart`
Potrzeba też dostosować od razu metodę createDraft żeby przyjmowała też parametr liczby drużyn i listę reguł.

co do reguł też potrzebujemy jakiegoś sposobu na przechowywanie ich. 

Proponuję taką strukturę:

enum DraftRuleType:
- together
- against

class DraftRule
DraftRuleType type
list<player> players

W taki sposób przekazujemy list<Rule>


----

Tworzenie skomplikowanych draftów trwa całkiem długo - spróbujmy przenieśc logikę do RPC i zapisywać jego status w db:

drafts:
draft_id
squad_id
status
proposals (int)

draft_payloads:
draft_id
payload 


---
do tego w matches i tournament dodajemy kolumnę draft_id